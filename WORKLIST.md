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

- [x] 1. 從 GAMEPC (29KB DOS exe) 萃取所有 ASCII 字串
- [x] 2. 分析 STRIPPED.TXT (TEXT02-TEXT30 + TABLES 參照)
- [x] 3. 分析 SIMON.GME offset table 結構 (425 resource slots)
- [x] 4. 從 GME 萃取場景內嵌文字 (TEXT02-TEXT30, 28 區塊, 880 條)
- [x] 5. 建立完整字串清單 `strings/final_untranslated.txt`

## 第三輪:CJK 字型

- [x] 6. 建立 CJK 專用字型 pipeline (tools/build_cjk_font.py + Docker)
- [x] 7. 選擇並配置系統 CJK 字型 (WQY Zen Hei / Noto Sans CJK TC)
- [x] 8. 烘製 `simon_zh12.dcjk` (12×12 點陣, 13710 字, Big5 線性索引)
- [x] 9. 烘製 `simon_zh16.dcjk` (16×16 點陣, 對白大字)

## 第四輪:AGOS 引擎 CJK patch

### 4A:基礎設施

- [x] 10. 新增 `engines/agos/cjk_cht.h` — CJK 常數、函式宣告
- [x] 11. 新增 `engines/agos/cjk_cht.cpp` — DCJK 載入、Big5 index、翻譯查表
- [x] 12. 修改 `agos.h` — 新增 CJK 成員變數
- [x] 13. 修改 `agos.cpp` — CJK 初始化 (loadCJKFont、loadCHTTable)
- [x] 14. 修改 `detection_tables.h` — Simon 1 加入 ZH_TWN 語言選項

### 4B:視窗文字渲染 (windowDrawChar)

- [x] 15. 修改 `charset-fontdata.cpp:windowDrawChar()` — CJK 繪字分支
- [x] 16. 修改 `charset.cpp:windowPutChar()` — CJK 字寬/換行

### 4C:字幕渲染 (renderString)

- [x] 17. 修改 `charset-fontdata.cpp:renderString()` — CJK 疊圖層 (renderStringCJK)
- [x] 18. 修改 `string.cpp:printScreenText()` — CJK 字串寬度+換行
- [x] 19. 更新 `string.cpp:getPixelLength()` — CJK 字寬計算

### 4D:翻譯注入

- [x] 20. 修改 `string.cpp:getStringPtrByID()` — 翻譯查表注入
- [~] 21. 修改 `script_s1.cpp` — 各 printScreenText() 點注入翻譯 (部分)
- [~] 22. 修改 `verb.cpp` — 動詞列注入翻譯 (部分)

### 4E:使用者體驗

- [x] 23. F8 切換中英文字 (攔截 `event.cpp` → `_chtTextOn` toggle)
- [ ] 24. 啟動時顯示「繁體中文化」提示

### 4F:編譯

- [x] 25. 修改 `module.mk` — 加入 `cjk_cht.o`
- [x] 26. 編譯 patched ScummVM (configure: `--enable-engine=agos --disable-all-engines`)

## 第五輪:翻譯

- [x] 27. 建立 `translations/zh.tsv` (TSV 格式)
- [x] 28. 建立 `tools/build_translation.py` (UTF-8 TSV → Big5 `.tab`)
- [x] 29. 翻譯動詞列 (10 個動詞)
- [x] 30. 翻譯常用系統訊息 (~20 條)
- [x] 31. 翻譯物件名稱與描述 (~250 條)
- [x] 32. 翻譯完整對白 (GME 880 條: TEXT02-TEXT30)

## 第六輪:打包與測試

- [x] 33. Linux AppImage 打包 (simon1-cht-x86_64.AppImage, 31MB)
- [ ] 34. Windows 跨編譯打包
- [x] 35. 實機 headless 驗證 (CJK 載入 + 1237 條翻譯表)
- [x] 36. 寫 README.md

---

## 進度追蹤

| 輪次 | 完成/總 | 狀態 |
|------|---------|------|
| 第一輪 基礎建設 | 6/6 | ✅ 完成 |
| 第二輪 字串萃取 | 5/5 | ✅ 完成 |
| 第三輪 CJK 字型 | 4/4 | ✅ 完成 |
| 第四輪 AGOS patch | 15/17 | 🟡 進行中 |
| 第五輪 翻譯 | 6/6 | ✅ 完成 (1237 條) |
| 第六輪 打包測試 | 0/4 | ⬜ 待做 |
| **總計** | **36/42** | |
