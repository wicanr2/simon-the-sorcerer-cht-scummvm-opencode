/* ScummVM - Graphic Adventure Engine
 * AGOS engine - Simon the Sorcerer Traditional Chinese (Big5) overlay.
 * Non-upstream localisation helper. See cjk_cht.h.
 */

#include "agos/cjk_cht.h"
#include "common/hashmap.h"
#include "common/hash-str.h"
#include "common/str.h"
#include "common/textconsole.h"
#include "common/file.h"

namespace AGOS {
namespace CHT {

// Translation table: English key -> Big5 value
static Common::HashMap<Common::String, Common::String> *_chtTable = nullptr;

int big5LinearIndex(byte lead, byte trail) {
	if (lead < 0x81 || lead > 0xFE)
		return -1;
	int to;
	if (trail >= 0x40 && trail <= 0x7E)
		to = trail - 0x40;          // 0..62
	else if (trail >= 0xA1 && trail <= 0xFE)
		to = 63 + (trail - 0xA1);   // 63..156
	else
		return -1;
	return (lead - 0x81) * 157 + to;
}

int loadTable(byte *buf, uint32 size) {
	if (!_chtTable)
		_chtTable = new Common::HashMap<Common::String, Common::String>();

	uint32 pos = 0;
	int count = 0;

	while (pos + 2 < size) {
		// Read null-terminated key
		uint32 keyStart = pos;
		while (pos < size && buf[pos] != 0) pos++;
		if (pos >= size) break;
		uint32 keyLen = pos - keyStart;
		if (keyLen == 0) { pos++; continue; }

		Common::String key((const char *)&buf[keyStart], keyLen);
		pos++; // skip null

		// Read null-terminated value (Big5)
		uint32 valStart = pos;
		while (pos < size && buf[pos] != 0) pos++;
		if (pos >= size) break;
		uint32 valLen = pos - valStart;
		pos++; // skip null

		if (valLen == 0) continue;

		Common::String val((const char *)&buf[valStart], valLen);
		(*_chtTable)[key] = val;
		count++;
	}

	return count;
}

void normalizeKey(const char *src, char *dst, uint32 dstSize) {
	uint32 di = 0;
	while (*src && di < dstSize - 1) {
		byte c = *src;
		// Skip control codes / high bytes that are part of ScummVM internal formatting
		if (c == 0xFF) {
			src++; // skip 0xFF
			if (*src) src++; // skip next byte (opcode)
			continue;
		}
		// Collapse whitespace
		if (c <= 0x20 || c == 0x7F) {
			if (di > 0 && dst[di - 1] != ' ')
				dst[di++] = ' ';
			src++;
			continue;
		}
		dst[di++] = c;
		src++;
	}
	// Trim trailing space
	while (di > 0 && dst[di - 1] == ' ') di--;
	dst[di] = 0;
}

bool translateInPlace(char *buf, uint32 bufSize) {
	if (!_chtTable || !buf || bufSize == 0)
		return false;

	// Normalize key for lookup
	char normKey[256];
	normalizeKey(buf, normKey, sizeof(normKey));

	if (normKey[0] == 0)
		return false;

	Common::HashMap<Common::String, Common::String>::iterator it =
		_chtTable->find(Common::String(normKey));

	if (it == _chtTable->end()) {
		dumpMiss(normKey);
		return false;
	}

	const Common::String &val = it->_value;
	if (val.size() + 1 > bufSize)
		return false;

	memcpy(buf, val.c_str(), val.size());
	buf[val.size()] = 0;
	return true;
}

// ---- Dump mode ----

static int _dumpOn = 0;
static Common::HashMap<Common::String, bool> _dumped;

void dumpInit() {
	if (_dumpOn == 0) {
		_dumpOn = Common::File::exists("simon_dump_on") ? 1 : -1;
	}
}

void dumpMiss(const char *key) {
	if (_dumpOn <= 0)
		return;
	if (_dumped.contains(Common::String(key)))
		return;
	_dumped[Common::String(key)] = true;
	warning("CHTMISS\t%s", key);
}

} // namespace CHT
} // namespace AGOS
