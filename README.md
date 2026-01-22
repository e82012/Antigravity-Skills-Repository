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
- **邊界防守**：專抓 `null`、`undefined` 或潛在的 Memory Leak。
- **語義化命名**：告別 `temp` 與 `data`，確保代碼具備自我解釋能力。
- **分級回饋**：提供 `[BLOCKER]`, `[CHORE]`, `[IDEA]` 不同層級的精準建議。

### 3. [UI 美學工匠 (UI-SKILL)](./ui-skill/SKILL.md)
**「拒絕工程師審美的平庸 UI。」**
- **呼吸感**：嚴格執行 **8px 網格系統**，讓畫面有序排列。
- **視覺層次**：透過陰影、字重、間距打造高級感，而非死板的表格。
- **交互靈魂**：Hover、Focus、Transition 是標配，讓操作有情感回饋。

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
`C:\Users\YourName\.gemini\antigravity\global_skills\ui-skill`

### 專案級使用
你也可以直接將特定技能資料夾放入個別專案的 `.gemini/antigravity/skills/` 目錄下，使其僅在該專案中生效。

## 📂 目錄結構
```text
AntiGravity-Skill/
├── global-rules/     # 執行邏輯與安全性
├── code-review/      # 程式碼品質與 CR 規範
├── ui-skill/         # UI/UX 美學與細節
└── README.md         # 這裡就是起點
```

---
