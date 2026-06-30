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
- **一致性規格**：確認輸入、輸出與邊界條件，避免需求變形.
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

### 6. [幾何圖元擬合專家 (Geometrize Expert)](./geometrize-expert/SKILL.md)
**「用幾何拼貼重構視覺。」**
- **演算法核心**：Hill Climbing 搜索、CMA-ES 自適應進化與殘差解析。
- **採樣引導**：Edge-Guided Sobel 邊緣圖引導採樣與 Edge-Aware 評分。
- **GPU 加速**：OpenCL kernel 平行評估與生命週期優化。
- **輸出規格**：Forza Painter 座標系轉換與 JSON 邊界保護。

### 7. [RESTful API 規格書產生器 (RESTful API Spec Writer)](./restful-api-spec-writer/SKILL.md)
**「把需求變成可交付的 API 規格。」**
- **標準化輸出**：強制套用完整的 RESTful API 規格書模板。
- **設計規範**：統一資源命名、HTTP Method、路徑層級與狀態碼語意。
- **多 API 交付**：支援將複雜需求拆解為多支 API 並逐一完整描述。

### 8. [AI 統一回應格式 (Unified Response Format)](./unified-response-format/SKILL.md)
**「讓需求討論變得清楚、可驗收。」**
- **結構化回應**：統一需求理解、已明確/未明確項目、風險與策略分析。
- **決策品質**：強制列出風險、替代方案與前提驗證，避免盲目收斂。
- **驗收導向**：內建 BDD / 驗收檢查，方便對齊 PM 與工程交付。

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
`C:\Users\YourName\.gemini\antigravity\global_skills\geometrize-expert`
`C:\Users\YourName\.gemini\antigravity\global_skills\restful-api-spec-writer`
`C:\Users\YourName\.gemini\antigravity\global_skills\unified-response-format`

### 專案級使用
你也可以直接將特定技能資料夾放入個別專案的 `.gemini/antigravity/skills/` 目錄下，使其僅在該專案中生效。

## 📂 目錄結構
```text
AntiGravity-Skill/
├── global-rules/           # 執行邏輯、決策順序與安全性
├── code-review/            # 程式碼品質、後端審查與 CR 規範
│   └── resources/          # CR 報告模板與檢查表
├── feature-analysis-skill/ # 需求分析、可行性評估與功能拆解
│   └── resources/          # 功能需求分析與方案比較模板
├── frontend-design/        # 前端工程技巧、性能與無障礙
│   └── examples/           # 無障礙互動元件與 CSS 範例
├── ui-skill/               # UI 美學設計、色彩、排版與動效
│   └── resources/          # 視覺 Token 設計範本
├── geometrize-expert/      # 幾何圖元擬合演算法與加速
│   └── examples/           # OpenCL kernel 與座標轉換範例
├── restful-api-spec-writer/ # RESTful API 規格書與接口設計
├── unified-response-format/ # 統一的需求、方案與驗收回應模板
└── README.md               # 這裡就是起點
```

---
