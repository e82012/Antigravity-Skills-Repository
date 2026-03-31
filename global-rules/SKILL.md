---
name: Antigravity 全局準則 (Global Rules)
description: 全局準則
---

# Antigravity 全局準則 (Global Rules)

## 1. 任務執行習慣 (Execution Preferences)

- **思考先行 (Think First)**：在執行任何複雜重構或跨檔案修改前，必須先輸出簡短的 **[Plan]**，列出執行步驟與受影響的檔案。
- **精準搜索 (Search Before Guessing)**：嚴禁猜測專案內部 API 的定義。遇到未知函式或元件時，優先使用全域搜索或跳轉至定義進行確認。
- **終端感知 (Terminal Awareness)**：執行命令報錯後，自動讀取終端輸出並嘗試修復，直到任務成功或需使用者介入。
- **上下文剪裁 (Context Pruning)**：保持「只看相關程式碼」的習慣。處理特定模組時，主動忽略無關邏輯，以提升推理準確度並節省 Token。
- **視覺化思考 (Visual Thinking)**：解釋複雜邏輯、系統架構或工作流時，優先使用 **Mermaid 圖表**進行輸出。

---

## 2. 程式碼品質與規範 (Code Style & Quality)

- **最小化衝擊 (Minimum Impact)**：保持專案原始風格（如縮進、引號習慣）。僅修改與任務直接相關的程式碼，避免非必要的全檔案格式化。
- **現代標準 (Modern Standards)**：除非另有說明，優先使用現代語法（如 ES Modules, async/await, Python 3.10+ 特性）。
- **型別安全 (Type Safety)**：在 TS 專案中，嚴禁在無說明的情況下使用 `any`。必須定義 Interface 或 Type 以保持嚴謹。

---

## 3. 安全與邊界 (Safety & Constraints)

- **受保護檔案 (Protected Files)**：禁止修改 `.env`, `package-lock.json`, `pnpm-lock.yaml` 或任何金鑰檔案，除非任務目標明確要求。
- **數據隱私 (Data Privacy)**：不可將包含敏感個人資訊或正式環境金鑰的程式碼區塊傳送至模型進行分析。
- **預演確認 (Dry Run)**：涉及 `rm -rf` 或危險的資料庫操作時，必須先在終端印出完整命令並等待手動確認。

---

## 4. IDE 協作特性 (IDE Specifics)

- **聚焦處理 (Active Focus)**：優先處理當前編輯器中處於活動狀態（Focus）的檔案。
- **自動校驗 (Auto-Validate)**：修改完成後，主動檢查 IDE 的錯誤提示（Linter Errors）。若有新增紅字，立即自行修正。
- **完工定義 (Definition of Done)**：修改後必須執行相關驗證指令（如 `npm run lint`, `npm test`），確保程式碼不僅「寫對」且「能跑」。

---

## 5. 決策與執行策略 (Decision Strategy)
- **優先順序 (Priority Order)**：
  1. 正確性 > 2. 安全性 > 3. 最小改動 > 4. 效能 > 5. 美觀
  當規則衝突時，必須依此排序決策。

- **停止條件 (Fail Fast)**：
  若同一問題連續嘗試修復 3 次仍失敗，必須停止並輸出：
  - 已嘗試的方法
  - 可能原因
  - 建議使用者介入點

- **避免過度推理 (Avoid Overthinking)**：
  若任務為單一檔案或明確需求，禁止進行跨模組分析。

---

## 6. 上下文控制強化 (Context Control)
- **局部優先 (Local First)**：
  優先分析當前檔案，其次才是引用檔案，禁止無限制擴散分析。

- **最大關聯數 (Max Context Scope)**：
  同時參考檔案數量不得超過 5 個，避免上下文污染。

- **明確忽略 (Explicit Ignore)**：
  與當前任務無關的：
  - 測試檔案
  - 舊版程式碼
  - 註解掉的區塊
  必須主動忽略

---

## 7. 輸出控制 (Output Contract)
- **Plan 觸發條件**：
  僅在以下情況輸出 [Plan]：
  - 多檔案修改
  - 架構變動
  - 不確定性高

- **Plan 格式限制**：
  - 最多 5 步
  - 每步一句話
  - 必須包含檔案名稱

- **程式碼輸出規範**：
  - 僅輸出修改區塊（diff 或片段）
  - 禁止整檔重貼（除非必要）

---

## 8. 錯誤修復策略 (Error Recovery)
- **錯誤分類處理**：
  - Syntax Error → 直接修正
  - Runtime Error → 根據 log 分析
  - 邏輯錯誤 → 先提出假設再修改

- **禁止盲修 (No Blind Fixing)**：
  未讀取錯誤訊息前，不得進行修改

- **最小修復 (Minimal Fix)**：
  每次修正僅改動一個問題來源，避免連鎖錯誤

---

## 9. 智能偷懶機制
- **已知模式優先 (Pattern First)**：
  若問題屬於常見模式（CRUD、API 呼叫、表單處理），優先套用標準解法

- **避免重造輪子 (No Reinventing)**：
  若專案已有類似實作，必須優先複用

---

## 10.「不確定時怎麼辦」
- **不確定處理 (Uncertainty Handling)**：
  當資訊不足時：
  - 明確標註「假設」
  - 提供 1~2 種可能方案
  - 不可偽造不存在的 API 或行為