---
name: Code Review 專家準則 (CR Skills)
description: 專注於程式碼品質、邏輯邊界與維護性的審查規範
---

# Code Review 專家準則 (CR Skills)

## 1. 核心審查邏輯 (Review Logic)

- **邏輯完備性 (Logic Completeness)**：優先檢查邊界條件（Edge Cases）。審查時必須考慮：若輸入為 `null`、`undefined` 或空值，程式碼是否會崩潰？
- **效能瓶頸 (Performance Awareness)**：針對迴圈（Loops）與非同步操作進行審查。嚴禁在迴圈中執行不必要的 API 請求或複雜運算，並檢查是否有潛在的 Memory Leak。
- **可預測性 (Predictability)**：審查函式是否過於肥大？一個函式應只做一件事（Single Responsibility Principle）。

---

## 2. 程式碼整潔度 (Code Cleanliness)

- **命名語義化 (Semantic Naming)**：變數與函式命名必須直觀。嚴禁使用 `data1`, `temp`, `handleResult` 等模糊命名，應根據上下文建議更精確的名稱。
- **消除魔法數字 (No Magic Numbers)**：所有的硬編碼（Hardcoded）數值或字串必須提取為常量（Constants）或枚舉（Enums）。
- **註解必要性 (Comments Strategy)**：程式碼應盡量自我解釋（Self-documenting）。註解應說明「為什麼這樣做（Why）」，而非「在做什麼（What）」。

---

## 3. 安全與現代化 (Security & Modernity)

- **安全性掃描 (Security Audit)**：主動檢查是否有 SQL Injection、XSS 風險，或是不經意將敏感資訊（如 `console.log(token)`）殘留在代碼中。
- **語法演進 (Syntax Evolution)**：推薦使用更現代、更簡潔的寫法（例如使用 Optional Chaining `?.` 替代多層 `if` 判斷，或使用解構賦值）。
- **依賴檢查 (Dependency Review)**：若有引入新套件，審查其必要性與體積，避免為了一個簡單功能引入過重的程式庫。

---

## 4. 反饋回報規範 (Feedback Protocol)

- **分級建議 (Review Tiers)**：回饋時需標註層級：
  - **[BLOCKER]**: 嚴重 Bug 或安全性問題，必須修改。
  - **[CHORE]**: 命名或格式問題，建議修改。
  - **[IDEA]**: 關於架構優化的個人建議，供參考。
- **正面引導 (Positive Feedback)**：若程式碼寫得優雅、精簡，必須給予肯定，保持團隊開發氛圍（帥氣系開發者的基本禮儀）。