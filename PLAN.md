# PLAN — 魔法師西蒙 (Simon the Sorcerer) 繁體中文化

路線沿用姊妹專案 `atlantis` (*Fate of Atlantis* 繁中化) 的 engine-side overlay 做法。
不修改原版遊戲資料;patch ScummVM 在繪字處攔截英文 → 查表 → 用點陣 CJK 字型重畫到 hi-res 疊圖層。

---

## 第一性原理分析

### 本質問題
遊戲中文化 = **將螢幕上的英文字換成中文字**。拆解成四個子問題:

| 子問題 | atlantis (SCUMM 引擎) | simon (AGOS 引擎) |
|--------|----------------------|-------------------|
| **1. 原始文字在哪？** | SCUMM v5 bytecode 內嵌 | GAMEPC (DOS exe, 29KB ASCII) + SIMON.GME (game data) |
| **2. 字型如何渲染？** | 引擎已有 CJK 路徑 (charset.cpp `loadCJKFont`) | **完全沒有 CJK 基礎** — windowDrawChar() 用 8×8 1-bit bitmap;renderString() 用遊戲資料字型 |
| **3. 何時替換文字？** | `convertMessageToString` 後 injection | `getStringPtrByID` 後 injection |
| **4. 怎麼畫中文字？** | 既有 `get2byteCharPtr` + `printChar` 雙位元組渲染 | 需從零建立 CJK 點陣字型載入 + 雙 byte 描繪 |

### 關鍵差異:AGOS 引擎無 CJK 基礎設施

SCUMM 引擎已有 `loadCJKFont` / `get2byteCharPtr` / `_useCJKMode` / `_2byteWidth` 等全套雙位元組渲染，
且支援 `Common::ZH_TWN` (Big5) 語言路徑。補幾十行就能接上。

AGOS 引擎**完全沒有這些**。需要:
1. 從頭建立 DCJK 字型載入器
2. 在 `windowDrawChar` 加入 CJK 渲染分支
3. 在 `renderString` / `renderStringAmiga` 加入 CJK 疊圖層
4. 在 `getPixelLength` 加入 CJK 字寬計算
5. 處理雙 byte 字元檢測與換行

### 技術路線

```
遊戲原始字串 (GAMEPC ASCII)
  ↓ getStringPtrByID() 查詢
英文原文
  ↓ [inj] translation lookup (atlantis_zh.tab)
Big5 字串
  ├→ windowPutChar() → windowDrawChar() [CJK branch]
  │   └→ 繪製 Big5 點陣字到 window surface
  └→ printScreenText() → renderString() [CJK overlay]
      └→ 繪製 Big5 點陣字到 VGA sprite
```

---

## Phase 0 — 遊戲識別與引擎確認

| 項目 | 狀態 |
|------|------|
| 原始遊戲 | `original_game/SIMON.ISO` (CD-ROM DOS 1995 Infocom) |
| ISO 萃取 | ✅ `original_game/extracted/` — 20 個檔案 |
| ScummVM 引擎 | AGOS (`engines/agos/`)，位於 `/home/anr2/scummvm/qog-2/scummvm-src/` |
| Game ID | `GID_SIMON1` (DOS CD) 或 `GID_SIMON1DOS` (DOS Floppy) |
| 語言代碼 | 需新增 `Common::ZH_TWN` 路徑 (AGOS 目前不支援) |
| 文字所在 | GAMEPC (29KB, 純 ASCII) + SIMON.GME (6.9MB, 自訂編碼) |

## Phase 1 — 字串萃取

- [ ] 從 GAMEPC 萃取所有 ASCII 字串 (~估 1500+ 條)
- [ ] 分析 STRIPPED.TXT 的 TEXT/TABLES 分段結構，對應到 GME 內部文字區塊
- [ ] 從 SIMON.GME offset table 解出各場景內嵌文字
- [ ] 建立 `strings_raw.tsv` (英文原文 + 分類標籤)
- [ ] 建立 runtime 字串攔截機制 (dump mode, 參考 atlantis 的 `CHTMISS` log)

## Phase 2 — CJK 字型烘製

- [ ] 使用 atlantis 的 `tools/build_cjk_font.py` pipeline (TTF → Big5 點陣 atlas)
- [ ] 產出 `simon_zh16.dcjk` (16×16, 對話/物件名/動詞) 和 `simon_zh24.dcjk` (24×24, 大字對白)
- [ ] 選用系統 CJK 字型 (如 Noto Sans CJK TC / 文泉驛)

## Phase 3 — AGOS 引擎 CJK patch (核心)

這是整個專案最關鍵的階段，因 AGOS 引擎無 CJK 基礎設施。

### 3.1 新增 CJK 字型載入

- [ ] 新增 `engines/agos/cjk_cht.h` + `cjk_cht.cpp`:
  - DCJK 檔案載入 (header `DCJK` → 寬/高/字數/bitmap)
  - Big5 Linear Index 計算 (與 `build_cjk_font.py` 對齊)
  - 翻譯查表載入 (`simon_zh.tab` Big5)
  - `translateInPlace()` 就地英→中替換
  - dump 模式 (`simon_dump_on` 旗標檔 → 未翻字串 log)
- [ ] 修改 `agos.cpp` / `agos.h`:
  - 新增成員變數: `_useCJKMode`, `_cjkFontData`, `_cjkFontW`, `_cjkFontH`, `_chtTextOn`
  - 初始化時載入 DCJK 字型 (若 game 目錄有 `simon_zh16.dcjk`)
- [ ] 修改 `detection_tables.h`: 為 GID_SIMON1 加入 ZH_TWN 語言選項
- [ ] 修改 `module.mk`: 加入 `cjk_cht.o`

### 3.2 修改視窗文字渲染 (windowDrawChar)

- [ ] 修改 `charset-fontdata.cpp` `windowDrawChar()`:
  - 新增 CJK 分支 (當 `_useCJKMode` && char >= 0x80)
  - 讀取雙 byte (Big5 lead + trail)
  - 查 Big5 Linear Index → 從 CJK 字型 bitmap 取字
  - 繪製到 window surface (用 16px 高度)
- [ ] 修改 `charset.cpp` `windowPutChar()`:
  - CJK 字元寬度 = 12px (全形 = 2 個英文半形)
  - 處理換行邏輯 (英文用空格斷行, CJK 無空格需專用規則)

### 3.3 修改字幕渲染 (renderString)

- [ ] 修改 `charset-fontdata.cpp` `renderString()` / `renderStringAmiga()`:
  - 新增 CJK 疊圖層:在 VGA sprite buffer 上用 CJK 字型重畫
  - 保留原始背景還原機制
- [ ] 修改 `string.cpp` `printScreenText()`:
  - CJK 字串寬度計算 (`getPixelLength` 更新)
  - 自動換行: `lettersPerRow = width / 12` (CJK 12px 寬)

### 3.4 翻譯注入

- [ ] 修改 `string.cpp` `getStringPtrByID()`:
  - 回傳字串後注入 `translateInPlace()` 查表
  - 命中則將英文字串就地換成 Big5
- [ ] 修改 `script_s1.cpp`:
  - 各 `printScreenText()` 呼叫點加入翻譯 injection

### 3.5 使用者互動

- [ ] F8 切換中英文字 (參考 atlantis `input.cpp` 攔截)
- [ ] 遊戲內啟動時顯示「繁體中文化」提示橫幅

## Phase 4 — 翻譯

- [ ] 建立 `translations/zh.tsv` (TSV 格式: `英文<TAB>中文`)
- [ ] `tools/build_translation.py`: UTF-8 TSV → Big5 `.tab` binary
- [ ] 翻譯優先序:
  1. 動詞列 (Give/Pick up/Use/...共 ~9 個)
  2. 常用系統訊息
  3. 物件名稱與描述
  4. 完整對白

## Phase 5 — 打包與發布

- [ ] 編譯 patched ScummVM (只啟用 AGOS 引擎)
- [ ] Linux AppImage 打包
- [ ] Windows 跨編譯打包
- [ ] 建 README.md (上網搜尋 Simon the Sorcerer 相關資料)

---

## 與 atlantis 的關鍵差異

| 項目 | atlantis | simon (本專案) |
|------|----------|---------------|
| 引擎 | `scumm` (`GID_INDY4`) | `agos` (`GID_SIMON1`) |
| CJK 基礎 | 引擎內建 (v7+ gate) | **零基礎，需從頭建立** |
| 繪字函式 | `printChar` + `get2byteCharPtr` | `windowDrawChar` (8×8) + `renderString` |
| 字型格式 | 引擎已有 CJK 2byte 路徑 | 8×8 1-bit bitmap (硬編碼) |
| 翻譯注入點 | `convertMessageToString` 後 | `getStringPtrByID` 後 |
| Patch 規模 | ~726 行 (6 個檔案) | **估計 1500+ 行** (~10+ 檔案) |
| 文字來源 | SCUMM bytecode | GAMEPC (DOS exe ASCII) + GME |

## 安全鐵則

- 遊戲原始檔 (`original_game/`) 絕不進 git
- 只 push 工具、patch、`translations/`、docs
- CJK 字型使用系統字型，不內嵌版權字型
- 不直接複製 atlantis 的任何程式碼 (CLAUDE.md 要求)
