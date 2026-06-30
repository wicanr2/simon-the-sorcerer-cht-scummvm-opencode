#!/usr/bin/env python3
"""Build a Big5-indexed bitmap CJK font for the patched AGOS engine.

Output format (little-endian), read directly by the engine patch:
  magic   "DCJK"           (4 bytes)
  version u8 = 1
  width   u8   (e.g. 12)
  height  u8   (e.g. 12)
  bytesPerRow u8 = (width+7)//8
  encoding u8  (0 = Big5 linear index)
  reserved u8 x2
  numGlyphs u32
  glyphs[ numGlyphs * (bytesPerRow*height) ]  -- 1bpp, MSB-first per row

Glyph index = big5_linear(lead, trail):
  lead  0x81..0xFE  (126 leads)
  trail 0x40..0x7E (offset 0..62) | 0xA1..0xFE (offset 63..156)  -> 157 per lead
  index = (lead-0x81)*157 + trailoffset      (max 126*157 = 19782)
"""
import struct, argparse, sys
import freetype

LEAD_LO, LEAD_HI = 0x81, 0xFE
PER_LEAD = 157
NUM_GLYPHS = (LEAD_HI - LEAD_LO + 1) * PER_LEAD  # 19782

def trail_offset(trail):
    if 0x40 <= trail <= 0x7E: return trail - 0x40        # 0..62
    if 0xA1 <= trail <= 0xFE: return 63 + (trail - 0xA1)  # 63..156
    return -1

def big5_index(lead, trail):
    to = trail_offset(trail)
    if not (LEAD_LO <= lead <= LEAD_HI) or to < 0: return -1
    return (lead - LEAD_LO) * PER_LEAD + to

def make_renderer(size, font_path=None):
    if font_path:
        face = freetype.Face(font_path, index=0)
    elif size <= 14:
        # WQY Zen Hei Mono for small sizes (has embedded bitmaps)
        face = freetype.Face('/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc', index=2)
    else:
        # Noto Sans CJK for larger sizes
        face = freetype.Face('/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc', index=0)
    face.set_pixel_sizes(0, size)
    return face

def render_glyph(face, ch, width, height, bpr):
    """Return bytesPerRow*height bytes, 1bpp MSB-first, glyph baseline-positioned."""
    out = bytearray(bpr * height)
    try:
        face.load_char(ch, freetype.FT_LOAD_RENDER | freetype.FT_LOAD_TARGET_MONO)
    except Exception:
        return out

    bmp = face.glyph.bitmap
    bw, bh, bmp_pitch = bmp.width, bmp.rows, bmp.pitch

    if height > 14:
        ox = max(0, (width - bw) // 2)
        oy = max(0, (height - bh) // 2)
    else:
        top = face.size.ascender >> 6
        ox = max(0, face.glyph.bitmap_left)
        oy = top - face.glyph.bitmap_top

    for ry in range(bh):
        ty = oy + ry
        if ty < 0 or ty >= height: continue
        for rx in range(bw):
            tx = ox + rx
            if tx < 0 or tx >= width: continue
            byte_val = bmp.buffer[ry * bmp_pitch + (rx >> 3)]
            if byte_val & (0x80 >> (rx & 7)):
                out[ty * bpr + (tx >> 3)] |= (0x80 >> (tx & 7))
    return out

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--size', type=int, default=12, help='Font size in pixels')
    ap.add_argument('--out', required=True, help='Output .dcjk file')
    ap.add_argument('--font', help='TTF/TTC font path (defaults to system CJK fonts)')
    ap.add_argument('--subset', help='Text file with characters to subset (one per line)')
    args = ap.parse_args()

    w = h = args.size
    bpr = (w + 7) // 8
    face = make_renderer(args.size, args.font)

    # Build font atlas
    data = bytearray()
    data += b'DCJK' + struct.pack('<BBBBBxx I', 1, w, h, bpr, 0, NUM_GLYPHS)
    blank = bytes(bpr * h)
    glyphs = [blank] * NUM_GLYPHS
    rendered = 0

    if args.subset:
        # Subset mode: only render characters in the file
        with open(args.subset, 'r', encoding='utf-8') as f:
            chars = set(f.read())
        for ch in sorted(chars):
            if not ch.strip():
                continue
            b = ch.encode('big5', 'replace')
            if len(b) != 2:
                continue
            idx = big5_index(b[0], b[1])
            if idx < 0:
                continue
            g = render_glyph(face, ch, w, h, bpr)
            glyphs[idx] = bytes(g)
            rendered += 1
    else:
        # Full Big5 font
        for lead in range(LEAD_LO, LEAD_HI + 1):
            for trail in list(range(0x40, 0x7F)) + list(range(0xA1, 0xFF)):
                idx = big5_index(lead, trail)
                try:
                    ch = bytes([lead, trail]).decode('big5')
                except Exception:
                    continue
                g = render_glyph(face, ch, w, h, bpr)
                # Only store non-blank glyphs to save space (or store all if you want full coverage)
                glyphs[idx] = bytes(g)
                rendered += 1
            if (lead - LEAD_LO) % 16 == 0:
                print(f'  lead 0x{lead:02X} ... {rendered} glyphs rendered')

    for g in glyphs:
        data += g

    with open(args.out, 'wb') as f:
        f.write(data)

    print(f'Wrote {args.out}: {rendered} glyphs, {len(data)} bytes')

if __name__ == '__main__':
    main()
