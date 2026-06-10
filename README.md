# AntiGravity Skill Repository

這裡存放著 **Antigravity** 的核心靈魂。

## 🧠 技能模組 (The Skillsets)

### 1. [全局準則 (Global Rules)](./global-rules/SKILL.md)
**「想好了再動手。」** 這是身為開發者的基本修養。
- **思考先行**：拒絕盲目改 code，任何動作前先有 [Plan]。
- **安全邊界**：保護敏感資訊，執行危險指令（如 `rm`）前必須確認。
- **終端共感**：出錯時自動讀取 Log 並修正，不當伸手牌。
- **完工定義**：不只寫完，還要通過 Lint 與相關測試。

### 2. [Code Review 專家 (CR Skills)](./code-review/SKILL.md)
**「程式碼是寫給人看的，只是順便能執行。」**
- **流程框架**：意圖理解 → 邏輯正確性 → 邊界與安全 → 效能 → 風格。
- **邊界防守**：專抓 `null`、`0`、Race Condition 或潛在的 Memory Leak。
- **後端專項**：N+1 問題、Collation 衝突、Queue 冪等性、API 設計規範。
- **五級回饋**：`[BLOCKER]` `[WARNING]` `[CHORE]` `[IDEA]` `[PRAISE]` 精準分級。

### 3. [需求分析專家 (Feature Analysis)](./feature-analysis-skill/SKILL.md)
**「先搞懂問題，再設計解法。」**
- **問題拆解**：把複雜需求拆成最小可交付的功能模組。
- **價值判斷**：評估優先級、風險和成本，避免過度設計。
- **一致性規格**：確認輸入、輸出與邊界條件，避免需求變形。
- **回饋循環**：建立快速驗證點，讓設計與開發同步迭代。

### 4. [前端工程技巧 (Frontend Engineering)](./frontend-design/SKILL.md)
**「性能不是錦上添花，是基本盤。」**
- **CSS 架構**：原子化 Class 復用、CSS Modules 隔離、防禦性 CSS。
- **互動模式**：八種互動狀態、Modal/Popover 原生 API、鍵盤導航。
- **響應式工程**：Mobile-first、Container Queries、輸入方式偵測。
- **無障礙工程**：WCAG 對比度、Focus Ring、語義化標籤、44px 觸控目標。

### 5. [UI 美學設計 (UI Aesthetic Design)](./ui-skill/SKILL.md)
**「拒絕工程師審美的平庸 UI。」**
- **色彩理論**：OKLCH 色彩空間、染色中性灰、60-30-10 法則。
- **空間設計**：4pt 間距系統、視覺層次（模糊測試）、語義化 Elevation。
- **排版美學**：Modular Scale、Vertical Rhythm、字型配對原則。
- **動效美學**：100/300/500 時長法則、指數曲線、感知速度設計。

---

## 🛠️ 安裝與使用說明

### 全域技能放置 (Global Setup)
若要讓 Antigravity 在所有專案中都能自動載入這些技能，請將對應的資料夾同步至系統的全域技能目錄：

- **Windows Path**: `%USERPROFILE%\.gemini\antigravity\global_skills\`
- **Mac/Linux Path**: `~/.gemini/antigravity/global_skills/`

**操作範例 (Windows):**
將本倉庫中的資料夾移動或連結至：
`C:\Users\YourName\.gemini\antigravity\global_skills\global-rules`
`C:\Users\YourName\.gemini\antigravity\global_skills\code-review`
`C:\Users\YourName\.gemini\antigravity\global_skills\feature-analysis-skill`
`C:\Users\YourName\.gemini\antigravity\global_skills\frontend-design`
`C:\Users\YourName\.gemini\antigravity\global_skills\ui-skill`

### 專案級使用
你也可以直接將特定技能資料夾放入個別專案的 `.gemini/antigravity/skills/` 目錄下，使其僅在該專案中生效。

## 📂 目錄結構
```text
AntiGravity-Skill/
├── global-rules/           # 執行邏輯、決策順序與安全性
├── code-review/            # 程式碼品質、後端審查與 CR 規範
├── feature-analysis-skill/ # 需求分析、可行性評估與功能拆解
├── frontend-design/        # 前端工程技巧、性能與無障礙
├── ui-skill/               # UI 美學設計、色彩、排版與動效
└── README.md               # 這裡就是起點
```

---
