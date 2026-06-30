#!/usr/bin/env python3
"""Build a binary translation table from TSV source.

Input (stdin or file): UTF-8 TSV, one entry per line.
  Format: English<TAB>Chinese
  Lines starting with # are comments. Empty lines are skipped.

Output: Binary format for AGOS engine (null-terminated pairs).
  Format: <null-terminated English key><null-terminated Big5 value>
  Repeated for every entry. End of file terminates.

Usage:
  python3 tools/build_translation.py translations/zh.tsv > fonts/simon_zh.tab
"""

import sys
import os

def main():
    if len(sys.argv) > 1:
        with open(sys.argv[1], 'r', encoding='utf-8') as f:
            lines = f.readlines()
    else:
        lines = sys.stdin.readlines()

    entries = []
    for line in lines:
        line = line.strip()
        if not line or line.startswith('#'):
            continue

        parts = line.split('\t', 1)
        if len(parts) != 2:
            continue

        en = parts[0].strip()
        zh = parts[1].strip()

        if not en or not zh:
            continue

        # Encode Chinese to Big5
        try:
            zh_big5 = zh.encode('big5')
        except UnicodeEncodeError as e:
            print(f"WARNING: Cannot encode to Big5: '{zh}' - {e}", file=sys.stderr)
            continue

        entries.append((en, zh_big5))

    # Write binary table: null-terminated key, null-terminated Big5 value
    out = bytearray()
    for en, zh in entries:
        out += en.encode('ascii', 'replace')
        out += b'\x00'
        out += zh
        out += b'\x00'

    sys.stdout.buffer.write(out)

    print(f"Built table: {len(entries)} entries, {len(out)} bytes", file=sys.stderr)

if __name__ == '__main__':
    main()
