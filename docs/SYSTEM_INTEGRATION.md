# ScummVM AGOS 引擎 CJK 中文化整合經驗

本文件整理將 ScummVM AGOS 引擎加入繁體中文 (Big5) 支援的系統整合經驗，供其他專案參考。

---

## 一、核心原則

### 1. 不修改原始遊戲檔案

所有中文化透過 patch ScummVM 引擎達成。遊戲資料保持原樣，引擎在繪字處攔截英文並以中文重繪。

### 2. 分層架構

```
┌─────────────────────────────────────────┐
│  translations/zh.tsv    (UTF-8 TSV)     │ ← 人類編輯
│      ↓ tools/build_translation.py        │
│  simon_zh.tab           (Big5 binary)   │ ← 引擎讀取
├─────────────────────────────────────────┤
│  tools/build_cjk_font.py (freetype)     │
│      ↓ docker 執行                       │
│  simon_zh12.dcjk        (1bpp atlas)    │ ← 引擎讀取
├─────────────────────────────────────────┤
│  engines/agos/cjk_cht.cpp               │ ← Big5 索引 / 查表
│  engines/agos/agos.cpp                  │ ← DCJK 載入
│  engines/agos/charset.cpp               │ ← 字寬調整
│  engines/agos/charset-fontdata.cpp      │ ← CJK 繪字
│  engines/agos/string.cpp                │ ← 翻譯注入
└─────────────────────────────────────────┘
```

### 3. 參考專案結構 (atlantis)

atlantis (SCUMM 引擎) 的做法是 gold standard:
- SCUMM 引擎已有內建 CJK 基礎設施 (loadCJKFont, get2byteCharPtr, _useCJKMode)
- 只需補 Big5 線性索引 + 翻譯查表 (~726 行 patch)
- AGOS 引擎需從零建立 (430 行 patch)

---

## 二、DCJK 字型格式

### 設計決策

選用自訂 binary 格式而非內嵌 SCUMM 的 chinese.fnt，原因：
1. SCUMM 的 chinese.fnt 格式綁定 v7/v8，AGOS 無此基礎
2. 簡單 header + 1bpp bitmap 陣列，解析只需 ~15 行

### 格式定義

```
offset  size   description
0       4      magic "DCJK"
4       1      version = 1
5       1      width (pixels, e.g. 12)
6       1      height (pixels, e.g. 12)
7       1      bytesPerRow = (width+7)//8
8       1      encoding (0 = Big5 linear)
9       2      reserved
11      4      numGlyphs (LE, 19782 for full Big5)
15     ...     glyphs[numGlyphs * bytesPerRow * height]
               Each glyph: 1bpp MSB-first per row
```

### Big5 線性索引

```cpp
int big5LinearIndex(byte lead, byte trail) {
    if (lead < 0x81 || lead > 0xFE) return -1;
    int to;
    if (trail >= 0x40 && trail <= 0x7E)      to = trail - 0x40;       // 0..62
    else if (trail >= 0xA1 && trail <= 0xFE) to = 63 + (trail - 0xA1); // 63..156
    else return -1;
    return (lead - 0x81) * 157 + to;
}
```

### 字型烘製 (Docker)

```bash
docker run --rm -v $(pwd):/work -v /usr/share/fonts:/usr/share/fonts:ro \
    -w /work python:3.12-slim bash -c "
    apt-get install -y -qq libfreetype6
    pip install freetype-py
    python3 tools/build_cjk_font.py --size 12 --out fonts/simon_zh12.dcjk
"
```

重點：
- 使用系統字型 (WQY Zen Hei / Noto Sans CJK)
- freetype `FT_LOAD_TARGET_MONO` 產生 1bpp 點陣
- 12×12 適合 UI 文字，16×16 適合對白大字
- Docker 隔離環境，不污染系統

---

## 三、AGOS 引擎文字渲染架構

### 兩條渲染路徑

| 路徑 | 函式 | 用途 | CJK 做法 |
|------|------|------|----------|
| 視窗文字 | `windowDrawChar` (virtual) | UI/動詞/物品名 | override 用 DCJK 繪字 |
| 字幕 | `renderString` → VGA sprite | 對話/旁白 | 新增 `renderStringCJK` |

### windowDrawChar 覆寫

```cpp
void AGOSEngine_Simon1::windowDrawChar(WindowBlock *window, uint x, uint y, byte chr) {
    if (!_chtCJKMode || _forceAscii || !_cjkFontData) {
        AGOSEngine::windowDrawChar(window, x, y, chr);  // fallback
        return;
    }

    // Big5 double-byte assembly
    if (_cjkCurChar != 0) {
        // Trail byte: combine and render
        int idx = CHT::big5LinearIndex((byte)_cjkCurChar, chr);
        _cjkCurChar = 0;
        // Render from _cjkFontData[idx] to screen surface
    } else if (CHT::isBig5Lead(chr)) {
        _cjkCurChar = chr;
        return;  // Wait for trail byte
    }
    // Single-byte: ASCII fallback
}
```

### renderStringCJK (字幕)

直接寫入 VGA sprite buffer (vgaFile2)，使用 DCJK 字型點陣。格式與原版 `renderString` 相容：
- 每行高度 = CJK 字高 (12px)
- 每字寬度 = CJK 字寬 - 1 (與原版一致，字元間 1px 間隙)
- 換行字元 `\n` 跳到下一行

---

## 四、翻譯系統

### 翻譯表格式

```
Binary: <null-terminated English key><null-terminated Big5 value>...
```

輸入是 UTF-8 TSV:
```
Walk to	走向
Look at	看
There's 8 of them.	總共有八個。
```

由 `tools/build_translation.py` 編譯為 Big5 binary `.tab` 檔。非 Big5 字元回報 warning。

### 注入點

```cpp
// string.cpp getStringPtrByID()
if (getGameType() == GType_SIMON1 && _language == Common::ZH_TWN && _chtTextOn) {
    CHT::translateInPlace((char *)dst, 180);
}
```

- 使用 `normalizeKey()` 剝除控制碼 (`0xFF` + code) 和空白
- `translateInPlace()` 就地 memcpy 中文覆蓋英文
- 注意保留語音觸發碼 (talkie prefix)

### Dump 模式

在遊戲目錄放置空檔案 `simon_dump_on`:
```bash
touch game/simon_dump_on
```
啟動後所有未翻譯字串輸出為 `WARNING: CHTMISS <key>`，直接收整合適的翻譯鍵。

---

## 五、語言切換 (F8)

```cpp
// event.cpp KEYDOWN handler
if (getGameType() == GType_SIMON1 && _chtCJKMode
    && event.kbd.keycode == Common::KEYCODE_F8) {
    _chtTextOn = !_chtTextOn;
}
```

- `_chtTextOn` 控制翻譯注入 (`getStringPtrByID`) 和 CJK 渲染 (`printScreenText`)
- 切換後新繪文字即生效，不需重啟遊戲

---

## 六、AGOS vs SCUMM 引擎中文化差異

| 項目 | atlantis (SCUMM) | simon (AGOS) | 難度差異 |
|------|-----------------|-------------|----------|
| CJK 基礎 | 引擎內建 (v7+ gate) | 零，全部從頭建立 | AGOS +3x 工作量 |
| 雙 byte 檢測 | `is2ByteCharacter()` | 自寫 `isBig5Lead()` | 輕微 |
| 字型格式 | chinese.fnt (v7/v8) | DCJK (自訂 binary) | 相當 |
| 繪字函式 | `printChar()` | `windowDrawChar()` + `renderString()` | AGOS 多一個路徑 |
| 翻譯注入 | `convertMessageToString` 後 | `getStringPtrByID` 後 | 相當 |
| Patch 行數 | 726 行 | 430 行 | AGOS 較少 (因基礎設施少) |
| 編譯設定 | `--enable-engine=scumm` | `--enable-engine=agos` | 相當 |

---

## 七、踩過的坑

### 1. CJK 載入時機

**問題**: `setupGame()` 在 `_language` 解析前呼叫，導致 language 被覆寫。
**解法**: 在 `init()` 最後 (syncSoundSettings 之後) 呼叫 CJK 載入。

### 2. 英文版字幕預設關閉

**問題**: Simon1 DOS CD 英文版 `_subtitles = false`，CJK 模式需強制開啟。
**解法**: `loadCJKFont()` 中設定 `_subtitles = true; _speech = false;`

### 3. Big5 雙 byte 狀態機

**問題**: `windowDrawChar` 每次只收一個 byte，Big5 是兩個 byte。
**解法**: `_cjkCurChar` 儲存 lead byte，下次呼叫時組合渲染。

### 4. 自動換行寬度

**問題**: CJK 字元 12px 寬 vs ASCII 6px 寬。
**解法**: `printScreenText` 中動態調整 `lettersPerRow = width / 12`。

### 5. Docker 權限

**問題**: docker 產出檔案 root 擁有，host 無法寫入。
**解法**: `docker run` 後用 `chown`，或在 docker 內 cp 到掛載目錄。

---

## 八、移植到其他 AGOS 遊戲

本 patch 專為 Simon 1 設計，但可移植到其他 AGOS 引擎遊戲 (Simon 2, Feeble Files 等):

1. 在對應的 `AGOSEngine_*` subclass 加入 CJK 成員
2. 在 `init()` 末呼叫 `loadCJKFont()` (限定 game type)
3. 覆寫 `windowDrawChar` (如需要)
4. 在 `string.cpp` 加入對應 game type 的翻譯注入
5. 烘製對應的字型檔 (不同遊戲可能需要不同字型大小)

關鍵是 AGOS 引擎的 `windowDrawChar` 是 virtual 的，每個遊戲可以獨立覆寫。

---

## 九、與 atlantis 專案的 asset 共用

兩個專案共享以下工具鏈：
- `tools/build_cjk_font.py` — 字型烘製 (只需改輸出路徑和字型大小)
- `tools/build_translation.py` — 翻譯表編譯 (通用)
- DCJK 格式相容 (atlantis 的 12×12 字型可直接用於 simon)

不共享的部分：
- engine patch (scumm vs agos 差異太大)
- 翻譯內容 (遊戲專屬)

---

*最後更新: 2026-06-30*
