/* ScummVM - Graphic Adventure Engine
 * AGOS engine - Simon the Sorcerer Traditional Chinese (Big5) overlay.
 * Non-upstream localisation helper.
 */

#ifndef AGOS_CJK_CHT_H
#define AGOS_CJK_CHT_H

#include "common/scummsys.h"

namespace AGOS {

class AGOSEngine_Simon1;

namespace CHT {

// Big5 linear index to match tools/build_cjk_font.py glyph ordering.
// Returns glyph index (0..19781) or -1 for invalid byte pairs.
int big5LinearIndex(byte lead, byte trail);

// Test if a byte is the start of a Big5 two-byte character.
// Big5 lead bytes: 0x81-0xFE
inline bool isBig5Lead(byte c) { return c >= 0x81 && c <= 0xFE; }

// Test if a byte is a valid Big5 trail byte.
// Big5 trail bytes: 0x40-0x7E, 0xA1-0xFE
inline bool isBig5Trail(byte c) { return (c >= 0x40 && c <= 0x7E) || (c >= 0xA1 && c <= 0xFE); }

// Load a translation table file (binary format: null-terminated pairs).
// Returns number of entries loaded.
int loadTable(byte *buf, uint32 size);

// Translate a string in-place: if the string is found in the translation table,
// overwrite it with the Big5 Chinese text. Returns true if translated.
bool translateInPlace(char *buf, uint32 bufSize);

// Normalize a string key for table lookup: strip control chars, collapse whitespace.
void normalizeKey(const char *src, char *dst, uint32 dstSize);

// Dev aid: dump untranslated strings to log if dump flag is set.
void dumpInit();
void dumpMiss(const char *key);

} // namespace CHT

} // namespace AGOS

#endif
