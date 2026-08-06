# AntiGravity Skill Repository

這裡存放著 **Antigravity** 的核心靈魂。

## 🧠 技能模組 (The Skillsets)

### 1. [全局準則 (Global Rules)](./global-rules/SKILL.md)
**「想好了再動手。」** 這是身為開發者的基本修養，也是所有 AI 代理共用的規則本體。
- **誠實與查證**：不知道就說不知道；禁止把業界通例包裝成「本專案事實」；宣稱「A 依賴 B」必須讀到實際那一行程式碼。
- **思考先行**：拒絕盲目改 code，任何動作前先有 [Plan]。
- **安全邊界**：保護敏感資訊，執行危險指令（如 `rm`）前必須確認；新版驗證通過前，來源檔不刪、不覆寫。
- **終端共感**：出錯時自動讀取 Log 並修正，不當伸手牌。
- **完工定義**：不只寫完，還要通過 Lint 與相關測試。
- **文件撰寫**：交付文件只寫結論性事實，開發歷程留在對話與 git log。
- **隨附參考知識**：`resources/` 內含衝突決策速查、台灣用語對照、查證深度規則、git 手冊、小工具設計準則。

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

### 8. [Agent 使用日誌 (Agent Daily Log)](./agent-daily-log/SKILL.md)
**「把每日工作與決策記錄成可追蹤的日誌。」**
- **任務追蹤**：記錄今日完成的工作、時間與使用模型。
- **平行處理紀錄**：保存哪些任務同時執行、哪些刻意不平行。
- **決策案例**：留下模型選擇與方案取捨的理由，方便日後回顧。
- **學習與規劃**：整理當日學習心得與明日計畫，支援持續改善。

### 9. [AI 統一回應格式 (Unified Response Format)](./unified-response-format/SKILL.md)
**「讓需求討論變得清楚、可驗收。」**
- **結構化回應**：統一需求理解、已明確/未明確項目、風險與策略分析。
- **決策品質**：強制列出風險、替代方案與前提驗證，避免盲目收斂。
- **驗收導向**：內建 BDD / 驗收檢查，方便對齊 PM 與工程交付。

### 10. [Prompt 紅藍軍對抗測試 (Prompt Red/Blue Team)](./prompt-redteam/SKILL.md)
**「先讓自己人打穿一次，總比上線後被使用者打穿好。」**
- **單一 session 分飾兩角**：同一個 agent 依序扮演紅軍（攻擊）與藍軍（防禦評估），不用另開多 agent。
- **8 大攻擊分類**：指令覆寫、角色扮演繞過、系統提示洩漏、編碼混淆、多輪社交工程、權限提升、資料外洩誘導、假設情境繞過。
- **結構化報告**：受測規則清單、逐項攻防紀錄、高風險摘要、可直接套用的修補措辞。

### 11. [Apple 設計審查 (Apple Design Review)](./apple-design/SKILL.md)
**「設計原則是通用的，實作細節才分平台。」**
- **HIG 濃縮**：把 Apple 人機介面指南 55 個主題壓縮成一份 `hig-cheatsheet.md`，跨框架通用。
- **五大審查透鏡**：無障礙 → 平台慣例 → 視覺 → 互動 → 文案，依嚴重度分級。
- **平台翻譯**：iOS/macOS 術語自動對應到 Flutter / Tauri / Electron / React Native。
- **專項模式**：App Icon、無障礙稽核、深色模式、生成式 AI UX、Liquid Glass 玻璃擬態。

### 12. [Apple 流暢動效 (Apple Fluid Motion)](./apple-fluid-motion/SKILL.md)
**「介面活起來的那一刻，它就不再像電腦，而是你的延伸。」**
- **實作導向**：Apple WWDC《Designing Fluid Interfaces》濃縮成 Web(CSS / Pointer Events / Motion 彈簧)可落地規則。
- **彈簧與手勢**：damping/response 參數表、velocity handoff、動量投射 `project()` 公式、rubber-banding。
- **可中斷原則**：任何動畫隨時可被抓住並反向，一律從當前畫面值出發，避免跳動。
- **材質與字體**：半透明玻璃層級、reduced-motion 三訊號、字體 tracking/leading 光學調校。
- **與 apple-design 分工**：這是「怎麼做」(build)，apple-design 是「審查什麼」(review)。

### 13. [Gemini 紅藍對抗審查 (Gemini Red/Blue Team Review)](./gemini-redteam/SKILL.md)
**「一個人審查自己的方案永遠有盲點，找另一個獨立的 AI 來挑刺。」**
- **雙 AI 對抗**：Claude Code 提方案 → 呼叫 `gemini` CLI 唯讀審查（`--approval-mode plan`，不執行任何操作）→ Claude 回應質疑，最多再來一輪。
- **固定收斂上限**：最多 2 輪 + 1 個 Claude 內部認定的最終輪，仍無共識就把雙方論點原文並列給使用者，不擅自選邊。
- **防迎合設計**：不讓 Gemini 知道是最終輪，並內建反迎合（anti-sycophancy）prompt，避免「時程壓力」「態度強硬」這類非技術理由被誤判為風險已解決。
- **模型額度 fallback**：`scripts/models.json` 維護備援模型清單，額度用盡自動換下一個，不需要事前查額度。
- **手動觸發**：僅在使用者明確要求時啟動，不因方案看起來複雜就自行判斷該不該叫 Gemini。

### 14. [工程流程技能組 (Engineering Flow)](./skill-map/SKILL.md)
**「想法 → 出貨，每一步都停在一個驗得出來的判準上。」** 15 個小而可組合的技能，改編自 [mattpocock/skills](https://github.com/mattpocock/skills)（MIT）與 [ihower 的 Harness Engineering 系列](https://ihower.tw/blog/13721-harness-engineering)。

- **兩種調用模式**：`disable-model-invocation` 把「要不要讓模型看到」變成明碼標價的取捨——保留 description 付上下文負載，拿掉則由人當索引。
- **原語＋包裝層**：`grilling` 是唯一的拷問本體，`grill-me`／`grill-with-docs` 只是兩個包裝層，改一次全部生效。
- **回饋迴路優先**：`bug-loop` 沒拿到一條會亮**紅燈**的緊迴路，就禁止進入假設階段——先腦補理論再找證據，從流程層擋掉；假設整批驗證失敗滿 3 輪，依全局準則 §8 停下來問人，不無限重跑。
- **雙軸平行審查**：`diff-review` 把規範軸與規格軸拆給兩個 sub-agent 並行，避免 context 互相污染；判斷準則直接引用既有的 `code-review`，不重抄。
- **獨立產出驗收**：`outcome-check` 派一個**全新 context** 的裁判實際操作產出（跑 API、開網頁、查資料庫），不是重讀程式碼——教會 agent 自我批判很難，找一個不受「作者覺得自己做對了」影響的裁判容易得多。`implement` 收尾自動接上，也能單獨手動叫。
- **從哪開始**：忘記該用哪個就叫 [`skill-map`](./skill-map/SKILL.md)（路由）；想改技能先讀 [`skill-craft`](./skill-craft/SKILL.md)（方法論本體＋詞彙表）。
- **使用說明**：落地方式、技能速查表、四個實戰劇本與狀況排除，見 [使用說明](./skill-map/resources/usage-guide.md)。

| 分層 | 技能 |
|------|------|
| 路由與方法論 | `skill-map`、`skill-craft` |
| 對齊 | `grilling`（原語）、`grill-me`、`grill-with-docs`、`domain-language` |
| 執行 | `tdd`、`bug-loop`、`diff-review`、`outcome-check` |
| 流程 | `setup-flow`、`to-spec`、`to-tickets`、`implement`、`handoff` |

**`outcome-check` 只是 Guides**——寫給模型讀的指引，靠模型自願遵守。要代碼層真正擋得住，用 [`outcome-check-harness`](./outcome-check-harness/README.md)：裝一個 Claude Code 的 `Stop` hook，模型想跳過驗收也跳不過。**只裝一次、對所有專案生效，不會碰任何專案目錄**——驗收條件用 `set-rubric.ps1` 針對單一專案設定，寫在使用者本機，不進該專案版控。這是需要明確授權才能安裝的工具，不是自動觸發的技能。第一版曾經把驗收條件放在專案目錄裡，拿真實專案測試後發現會被 `git status` 追蹤進去，已改成現在這個設計——過程與教訓見該工具自己的 README。

---

## 🛠️ 安裝與使用說明

### 全域技能放置 (Global Setup)

Antigravity 的全域 customization root 是 `~/.gemini/config/`，技能放在其下的 `skills/`：

- **Windows Path**: `%USERPROFILE%\.gemini\config\skills\`
- **Mac/Linux Path**: `~/.gemini/config/skills/`

每個技能一個資料夾，內含 `SKILL.md`：

```text
~/.gemini/config/skills/
├── global-rules/SKILL.md
├── code-review/SKILL.md
└── ...
```

用同步工具一次到位：

```powershell
pwsh -File tools\sync-skills.ps1 -Mode skills -Target gemini
```

> 舊路徑 `~/.gemini/antigravity/global_skills/` 已於 2026-05 遷移淘汰，不再被讀取。若該目錄下還有舊資料夾或 `.lnk` 捷徑，可自行清除。

### 不複製的替代方案：註冊外部路徑

Antigravity 支援用 `skills.json` 直接指向倉庫，改完立刻生效、不需要跑同步。在 `~/.gemini/config/skills.json` 寫入：

```json
{
  "entries": [
    { "path": "D:/AntiGravity-Skill", "exclude": ["tools", "global-rules"] }
  ]
}
```

`path` 支援絕對路徑與 `~/` 開頭的家目錄相對路徑，`exclude` 吃 regex。

### 專案級使用
專案內建立 `.agents/skills/<name>/SKILL.md`，即可讓該技能僅在該專案生效。也可在 `.agents/skills.json` 用工作區相對路徑註冊共用目錄，隨 repo 分享給團隊。

---

## 🤖 讓 Claude Code 套用全局準則

`global-rules` 同時是 Claude Code 的規則本體。但 Claude Code 裡「技能」與「全局準則」的載入時機不同，放錯位置會導致準則**平常不生效**：

| 放置位置 | 載入時機 |
|---|---|
| `~/.claude/skills/<name>/SKILL.md` | **按需觸發**——輸入 `/global-rules` 或模型判斷相關時才讀取 |
| `~/.claude/CLAUDE.md` | **每個 session 全載**，所有專案自動生效 |

只放進 `skills/` 等於準則要靠人記得呼叫。要讓它真正成為全局準則，必須建立 `~/.claude/CLAUDE.md`。

### 放置方式：一份本體，兩個入口

規則本體只保留一份，由 `CLAUDE.md` 轉指，避免兩份條文措辭漂移：

```text
~/.claude/
├── CLAUDE.md                    # 入口檔，只有幾行 import
└── skills/global-rules/         # 規則本體（本倉庫同步過去）
    ├── SKILL.md
    └── resources/               # 五份參考知識
```

**步驟 1**：跑同步工具，把 `global-rules/SKILL.md` 覆蓋成 `~/.claude/CLAUDE.md`，參考知識放到同層 `resources/`：

```powershell
pwsh -File tools\sync-skills.ps1 -Mode rules -Target claude -DryRun   # 先預演
pwsh -File tools\sync-skills.ps1 -Mode rules -Target claude           # 確認後執行
```

手動放置也可以，落點與注意事項見 [tools/README.md](./tools/README.md)。

**步驟 2**：驗證。開一個**全新 session**，不輸入任何 slash command，直接問「§4.1 的鐵則是什麼？」——答得出「新版本驗證通過前，來源檔不刪、不覆寫」代表載入成功。

`~/.claude/CLAUDE.md` 保存的是準則全文而非 `@import` 轉指，因為各代理的 import 語法不一致；由同步工具從單一來源產生，副本不會漂移。**目標端是產生物，要改規則請改本倉庫再重跑同步。**

### 注意事項

| 項目 | 說明 |
|---|---|
| 適用範圍 | `~/.claude/CLAUDE.md` 對該機器上**所有專案**生效，包含繁體中文回覆、台灣用語、中文註解。個別專案若需例外，在該專案自己的 `CLAUDE.md` 覆蓋——依 SKILL.md §12.1，專案規則優先於公版。 |
| 避免重複載入 | 專案級 `CLAUDE.md` 與使用者級 `CLAUDE.md` 會**疊加載入**。專案端不要再抄一份準則條文，只寫該專案專屬設定（環境、工具、路徑慣例）。 |
| 參考知識路徑 | `SKILL.md` §12.2 的 `resources/` 路徑以 SKILL.md 所在目錄為基準，即 `~/.claude/skills/global-rules/resources/`。 |
| 其他 CLI agent | 不會自動讀 `CLAUDE.md` 的代理（如 Codex）需另備 `AGENTS.md` 當入口，同樣只轉指、不複製條文。 |

## 📂 目錄結構
```text
AntiGravity-Skill/
├── global-rules/           # 誠實查證、執行邏輯、決策順序、安全性與文件規範
│   └── resources/          # 衝突決策速查、台灣用語對照、查證深度、git 手冊、工具設計準則
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
│   └── resources/          # API 規格書標準模板
├── agent-daily-log/        # Agent 日誌、任務紀錄與決策回顧
├── unified-response-format/ # 統一的需求、方案與驗收回應模板
├── prompt-redteam/         # Prompt 紅藍軍對抗測試、攻擊分類與報告模板
│   └── resources/          # 攻擊分類手冊與紅藍軍報告模板
├── apple-design/           # Apple HIG 設計審查（跨平台、濃縮版）
│   └── resources/          # hig-cheatsheet.md：55 主題濃縮速查表
├── apple-fluid-motion/     # Apple 流暢動效實作（Web：彈簧、手勢、材質）
├── gemini-redteam/         # Claude Code × Gemini CLI 紅藍對抗審查
│   └── scripts/            # consult-gemini.ps1（唯讀呼叫封裝）與 models.json（模型備援清單）
│
│   # ── 工程流程技能組（想法 → 出貨）─────────────────────
├── skill-map/              # 路由：忘記該用哪個技能時問它
│   └── resources/          # usage-guide.md：使用說明；source-analysis.md：設計依據
├── skill-craft/            # 寫技能與改技能的準則（方法論本體）
│   └── GLOSSARY.md         # 22 個詞條：調用、資訊階層、操舵、修剪四軸
├── grilling/               # 拷問原語（模型可調用，唯一本體）
├── grill-me/               # 包裝層：無倉庫時的拷問
├── grill-with-docs/        # 包裝層：有倉庫時的拷問，順手寫 CONTEXT.md 與 ADR
├── domain-language/        # 領域語言：詞彙表與 ADR 維護紀律
├── tdd/                    # 紅綠循環、接縫、測試反模式
│   └── resources/          # test-quality.md：好壞測試對照與 mock 界線
├── bug-loop/               # 除錯：回饋迴路優先於推理
│   └── resources/          # feedback-loops.md：十種造迴路的方式
├── diff-review/            # 雙軸差異審查（規範軸 × 規格軸，平行 sub-agent）
├── outcome-check/          # 獨立產出驗收：全新 context 裁判實際操作，非自我審計
├── setup-flow/             # 流程初始化：議題追蹤與領域文件配置
├── to-spec/                # 把對話收斂成規格
├── to-tickets/             # 切成曳光彈工單，標明阻擋邊
├── implement/              # 依票實作：tdd → diff-review → outcome-check → commit
├── handoff/                # 交棒：把對話壓成檔案，換新 session 接手
├── outcome-check-harness/  # outcome-check 的代碼強制版：Stop hook + 獨立 headless 裁判
│   ├── hooks/              # stop-outcome-check.ps1：真正的攔截邏輯
│   ├── install.ps1         # 裝一次，全域生效，不碰任何專案目錄
│   └── set-rubric.ps1      # 對單一專案啟用／查看／停用，寫在使用者本機
│   # ───────────────────────────────────────────────
│
├── tools/                  # 同步工具
│   ├── sync-skills.ps1     # 全局準則／技能一鍵同步到 Claude、Gemini、Codex
│   └── README.md           # 用法、退出碼、刻意不做什麼
└── README.md               # 這裡就是起點
```

## 🔧 本機工具速查

沒列進這張表的工具等於不存在，下一個 session 不會知道它，還可能重造一個。

| 工具 | 用途 | 詳見 |
|------|------|------|
| `tools/sync-skills.ps1` | 把本倉庫的全局準則與技能覆蓋到 Claude Code／Gemini Antigravity／Codex | [tools/README.md](./tools/README.md) |

---
**最後更新**: 2026-08-06
**維護者**: 開發團隊
**文件版本**: v3.2
**變更記錄**（里程碑，最多 5 條）:
- v3.2 (2026-08-06): 新增 `outcome-check-harness`——把 `outcome-check` 從提示詞層的 Guides 做成 Claude Code Stop hook 的代碼層 Sensor，全域安裝一次即對所有專案生效，不碰任何專案目錄；經端到端實測（含真實專案）修正三個真實 bug
- v3.1 (2026-08-04): 新增第 15 個技能 `outcome-check`（改編自 ihower 的 Harness Engineering 系列）——全新 context 裁判實際操作驗收，`implement` 收尾接上；`bug-loop`／`implement` 補迭代上限呼應全局準則 §8
- v3.0 (2026-08-04): 新增工程流程技能組共 14 個技能（改編自 mattpocock/skills，MIT），涵蓋路由、方法論、對齊、執行與流程五層；首次引入「使用者可調用 vs 模型可調用」的雙負載設計，以及原語＋包裝層的單一真實來源結構
- v2.1 (2026-07-30): 新增第 13 個技能 `gemini-redteam`（Claude Code × Gemini CLI 紅藍對抗審查），目錄結構同步補上
- v1.0–v2.0 (2026-01-22～2026-07-23): 首版建立技能模組索引，至新增跨代理同步工具、global-rules 升級為跨代理規則本體
