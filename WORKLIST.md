# WORKLIST — 魔法師西蒙 繁體中文化

> 每項目標注狀態: `[ ]` 待辦 / `[~]` 進行中 / `[x]` 完成

---

## 第一輪:基礎建設 (done)

- [x] 探索 SIMON.ISO 內容 — 20 個檔案, 182MB
- [x] 萃取 ISO 到 `original_game/extracted/`
- [x] 確認 ScummVM 引擎 = AGOS (`engines/agos/`)
- [x] 探索 atlantis 參考專案結構
- [x] 建立 PLAN.md (本檔)
- [x] 建立 WORKLIST.md (本檔)

## 第二輪:字串萃取

- [ ] 1. 從 GAMEPC (29KB DOS exe) 萃取所有 ASCII 字串 → `strings/gamepc_raw.txt`
- [ ] 2. 分析 STRIPPED.TXT (TEXT01-TEXT30 + TABLES01-30 參照)
- [ ] 3. 分析 SIMON.GME offset table 結構
- [ ] 4. 從 GME 萃取場景內嵌文字
- [ ] 5. 建立 `strings/all_strings.tsv` (ID, 英文原文, 分類, 場景)

## 第三輪:CJK 字型

- [ ] 6. 建立 CJK 專用字型 pipeline (參考 atlantis `tools/build_cjk_font.py`)
- [ ] 7. 選擇並配置系統 CJK 字型 (文泉驛微米黑 / Noto Sans CJK TC)
- [ ] 8. 烘製 `simon_zh16.dcjk` (16×16 點陣, Big5 線性索引)
- [ ] 9. 烘製 `simon_zh24.dcjk` (24×24 點陣, 大字對白用)

## 第四輪:AGOS 引擎 CJK patch

### 4A:基礎設施

- [ ] 10. 新增 `engines/agos/cjk_cht.h` — CJK 常數、函式宣告
- [ ] 11. 新增 `engines/agos/cjk_cht.cpp` — DCJK 載入、Big5 index、翻譯查表
- [ ] 12. 修改 `agos.h` — 新增 CJK 成員變數
- [ ] 13. 修改 `agos.cpp` — CJK 初始化 (loadCJKFont、loadTranslationTable)
- [ ] 14. 修改 `detection_tables.h` — Simon 1 加入 ZH_TWN 語言選項

### 4B:視窗文字渲染 (windowDrawChar)

- [ ] 15. 修改 `charset-fontdata.cpp:windowDrawChar()` — CJK 繪字分支
- [ ] 16. 修改 `charset.cpp:windowPutChar()` — CJK 字寬/換行

### 4C:字幕渲染 (renderString)

- [ ] 17. 修改 `charset-fontdata.cpp:renderString()` — CJK 疊圖層
- [ ] 18. 修改 `string.cpp:printScreenText()` — CJK 字串寬度+換行
- [ ] 19. 更新 `string.cpp:getPixelLength()` — CJK 字寬計算

### 4D:翻譯注入

- [ ] 20. 修改 `string.cpp:getStringPtrByID()` — 翻譯查表注入
- [ ] 21. 修改 `script_s1.cpp` — 各 printScreenText() 點注入翻譯
- [ ] 22. 修改 `verb.cpp` — 動詞列注入翻譯

### 4E:使用者體驗

- [ ] 23. F8 切換中英文字 (攔截 `input.cpp` → `_chtTextOn` toggle)
- [ ] 24. 啟動時顯示「繁體中文化」提示

### 4F:編譯

- [ ] 25. 修改 `module.mk` — 加入 `cjk_cht.o`
- [ ] 26. 編譯 patched ScummVM (configure: `--enable-engine=agos --disable-all-engines`)

## 第五輪:翻譯

- [ ] 27. 建立 `translations/zh.tsv` (TSV 格式)
- [ ] 28. 建立 `tools/build_translation.py` (UTF-8 TSV → Big5 `.tab`)
- [ ] 29. 翻譯動詞列 (9 個動詞)
- [ ] 30. 翻譯常用系統訊息 (~50 條)
- [ ] 31. 翻譯物件名稱與描述 (~300 條)
- [ ] 32. 翻譯完整對白 (依遊戲進度分批)

## 第六輪:打包與測試

- [ ] 33. Linux AppImage 打包
- [ ] 34. Windows 跨編譯打包
- [ ] 35. 實機 game tester 驗證
- [ ] 36. 寫 README.md

---

## 進度追蹤

| 輪次 | 完成/總 | 狀態 |
|------|---------|------|
| 第一輪 基礎建設 | 6/6 | ✅ 完成 |
| 第二輪 字串萃取 | 0/5 | ⬜ 待做 |
| 第三輪 CJK 字型 | 0/4 | ⬜ 待做 |
| 第四輪 AGOS patch | 0/17 | ⬜ 待做 |
| 第五輪 翻譯 | 0/6 | ⬜ 待做 |
| 第六輪 打包測試 | 0/4 | ⬜ 待做 |
| **總計** | **6/42** | |
