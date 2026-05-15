---
name: Code Review 專家準則 (CR Skills)
description: 專注於程式碼品質、邏輯邊界、安全性、後端審查與維護性的審查規範
---

# Code Review 專家準則 (CR Skills)

> **Version:** 2.0
> **Last Updated:** 2026-05-15
> **基礎依賴：** `global-rules` — 型別安全、最小化衝擊、錯誤修復策略等基礎規範
> **定位：** 程式碼審查時的判斷準則與流程規範

---

## 1. Review 流程框架 (Review Process)

### 審查順序

依下列順序進行，**不得跳過前項直接審查後項**：

```
1. 意圖理解 → 2. 邏輯正確性 → 3. 邊界與安全 → 4. 效能 → 5. 程式碼風格
```

- **意圖理解**：先理解這段程式碼**為什麼**要這樣寫，再判斷對錯。避免在不了解背景時直接批評。
- **範圍控制**：一次 Review 聚焦於變更範圍，不進行全檔案重構建議。超出範圍的改善以 `[IDEA]` 標註。

### 修改 vs 建議的判斷

| 情境 | 行動 |
|------|------|
| 明確的 Bug 或安全漏洞 | **直接修正**，標註 `[BLOCKER]` |
| 效能或邊界風險 | **提出修正建議**，標註 `[WARNING]` |
| 風格或命名問題 | **建議改善**，標註 `[CHORE]` |
| 架構方向討論 | **提出觀點**，標註 `[IDEA]` |
| 不確定的改動 | **提出假設，等待確認**，不直接修改 |

---

## 2. 核心審查邏輯 (Review Logic)

### 邏輯完備性 (Logic Completeness)

優先檢查邊界條件。以下是必查清單：

| 邊界類型 | 常見陷阱 |
|---------|---------|
| **Null / Undefined** | 未檢查即存取屬性 |
| **空陣列 `[]` vs `null`** | `foreach` 遇 `null` 崩潰，遇 `[]` 只是不執行 |
| **數值 `0`** | PHP 中 `empty(0)` 為 `true`，容易誤判 |
| **空字串 `""` vs `"0"`** | PHP `empty("0")` 為 `true` |
| **並發 (Race Condition)** | 兩個請求同時修改同一筆資料 |
| **大量資料 (Bulk)** | 100 筆 OK，100,000 筆呢？ |
| **時區** | 跨時區的日期比較與儲存 |

### 效能瓶頸 (Performance Awareness)

- **迴圈中的查詢**：嚴禁在迴圈中執行 DB 查詢或 API 請求（N+1 問題）
- **記憶體洩漏**：事件監聽器未解除、未關閉的連線、不斷增長的快取
- **批次操作**：大量資料應使用 `chunk()` 或 `cursor()` 分批處理
- **Placeholder 上限**：批次 INSERT/UPDATE 須注意 SQL placeholder 數量限制（通常 65,535）

### 可預測性 (Predictability)

- 一個函式只做一件事（Single Responsibility Principle）
- 函式過長時建議拆分，但**不得在 Review 中直接重構**（超出範圍時標註 `[IDEA]`）
- 回傳值型別應一致，避免同一函式有時回傳 `array`、有時回傳 `null`

---

## 3. 程式碼整潔度 (Code Cleanliness)

- **命名語義化 (Semantic Naming)**：嚴禁 `data1`, `temp`, `handleResult` 等模糊命名。變數名應反映其**業務含義**，而非技術角色。
- **消除魔法數字 (No Magic Numbers)**：所有硬編碼數值或字串必須提取為常量（Constants）或枚舉（Enums）。
- **註解策略 (Comments Strategy)**：程式碼應自我解釋（Self-documenting）。註解說明「**為什麼**這樣做（Why）」，而非「在做什麼（What）」。若程式碼需要大量 What 註解，代表命名或結構需要改善。

---

## 4. 安全審查 (Security Audit)

### 基礎掃描

| 風險 | 檢查項 |
|------|--------|
| **SQL Injection** | 使用參數綁定（Prepared Statements），禁止字串拼接 SQL |
| **XSS** | 輸出時轉義（Blade 用 `{{ }}`，禁止 `{!! !!}` 除非已手動清理） |
| **敏感資訊外洩** | 禁止 `console.log(token)` / `dd($password)` 殘留 |
| **Mass Assignment** | Laravel `$fillable` / `$guarded` 是否正確設定 |
| **CSRF** | 表單是否包含 `@csrf` |

### 進階掃描

- **Authorization vs Authentication**：不只確認「是否登入」，還要確認「是否有權限」（Policy / Gate / Middleware）
- **Rate Limiting**：敏感操作（登入、密碼重設、交易）是否有速率限制
- **Response 過度揭露**：API Response 是否返回了不必要的欄位（如密碼 hash、內部 ID、debug 資訊）
- **Log 安全**：Log 中禁止記錄密碼、Token、完整信用卡號等敏感資訊
- **語法演進 (Syntax Evolution)**：推薦使用更現代的寫法（Optional Chaining `?.`、解構賦值），但遵循最小化衝擊原則

---

## 5. 後端專項審查 (Backend Review)

### SQL 與資料庫

- **N+1 問題**：Eloquent 關聯是否使用 `with()` 預載入
- **索引使用**：WHERE / JOIN 欄位是否有對應索引，避免 Full Table Scan
- **Collation 衝突**：跨資料庫 JOIN 時強制指定 Collation（`COLLATE utf8mb4_unicode_ci`）
- **Transaction**：涉及多表寫入時是否包裹在 Transaction 中
- **Chunk 處理**：大量資料查詢使用 `chunk()` / `cursor()` 避免記憶體爆炸

### Laravel 特定

- **Queue 冪等性**：Job 重複執行時是否產生副作用
- **Service / Repository 分層**：業務邏輯是否放在 Service 層，而非 Controller 中
- **Config 快取**：是否使用 `config()` 而非 `env()`（`env()` 在 config cache 後失效）

### API 設計

- **Response 格式一致性**：成功 / 失敗的 Response 結構是否統一
- **分頁邏輯**：大量資料是否支援分頁，避免一次載入全部
- **錯誤碼規範**：HTTP Status Code 是否正確使用（如 `422` 用於驗證失敗，而非 `200` + error flag）

---

## 6. 錯誤處理審查 (Error Handling Review)

- **異常捕獲粒度**：禁止過寬的 `catch (Exception $e)` 吞掉所有錯誤。應捕獲具體的異常類型。
- **靜默失敗**：是否有邏輯分支默默失敗卻不記錄 Log？每個 `catch` 必須至少有 Log 或重新拋出。
- **錯誤傳播鏈**：前端 → API → 後端的錯誤訊息是否完整、可追蹤？
- **Retry 邏輯**：外部 API 呼叫失敗時，是否有合理的重試與退避策略？

---

## 7. 反饋回報規範 (Feedback Protocol)

### 五級回饋標籤

| 標籤 | 圖示 | 定義 | 行動要求 |
|------|------|------|---------|
| **[BLOCKER]** | 🔴 | 嚴重 Bug、安全漏洞、資料損壞風險 | **必須修改** |
| **[WARNING]** | 🟡 | 效能問題、邊界未覆蓋、潛在邏輯缺陷 | **強烈建議修改** |
| **[CHORE]** | 🔵 | 命名、格式、程式碼整潔度 | **建議修改** |
| **[IDEA]** | 💡 | 架構想法、替代方案、未來改善方向 | **供參考** |
| **[PRAISE]** | ✨ | 優雅實作、巧妙解法、值得學習的模式 | **正面肯定** |

### 回饋原則

- **正面引導 (Positive Feedback)**：若程式碼寫得優雅精簡，必須給予 `[PRAISE]` 肯定，保持團隊開發氛圍。
- **具體可操作**：每條回饋必須包含**問題描述**和**修改建議**，禁止只說「這裡有問題」而不說怎麼改。
- **依賴檢查 (Dependency Review)**：若引入新套件，審查其必要性與體積，避免為了一個簡單功能引入過重的程式庫。