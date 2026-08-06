# 工程流程技能組 — 使用說明

操作手冊。想知道「有哪些技能」看 [根 README](../../README.md)；想知道「這件事該走哪條路」叫 `skill-map`；想知道「實際怎麼敲」看這裡。

---

## 一、30 秒上手

```text
1. 讓代理讀得到這 14 個資料夾  → 見下方「二、落地」
2. 在專案裡跑一次 setup-flow   → 產出 docs/agents/flow-config.md
3. 忘記該用哪個技能時叫 skill-map
```

第 2 步每個倉庫只需要跑一次。沒跑也能用 `grilling`、`tdd`、`bug-loop`、`diff-review`——只有 `to-spec`、`to-tickets`、`implement` 會去讀那份設定。

---

## 二、落地

三種代理各自的落點。詳細指令與退出碼見 [`tools/README.md`](../../tools/README.md)。

### Antigravity

**方式 A：註冊外部路徑**（改完立刻生效，不用同步）。在 `~/.gemini/config/skills.json`：

```json
{
  "entries": [
    { "path": "D:/AntiGravity-Skill", "exclude": ["tools", "global-rules"] }
  ]
}
```

**方式 B：複製過去**

```powershell
pwsh -File tools\sync-skills.ps1 -Mode skills -Target gemini
```

### Claude Code

技能落 `~/.claude/skills/<name>/SKILL.md`：

```powershell
pwsh -File tools\sync-skills.ps1 -Mode skills -Target claude
```

### 專案級

只想在單一專案生效時，把資料夾放進該專案的 `.agents/skills/`（Antigravity）或 `.claude/skills/`（Claude Code）。

### 驗證有沒有吃到

開一個**全新 session**，輸入 `grilling`。代理開始一次問你一個問題，就代表載入成功。

---

## 三、技能速查表

**調用方式**欄位決定它怎麼被叫到——這是全組最重要的一欄，先看它：

| 技能 | 調用方式 | 什麼時候用 |
|------|---------|-----------|
| `skill-map` | 手動 | 忘記該用哪個技能 |
| `skill-craft` | 手動 | 要新增或修改技能；某個技能不聽話 |
| `setup-flow` | 手動 | 每個倉庫第一次跑流程之前 |
| `grill-me` | 手動 | 磨利一份不在倉庫裡的計畫 |
| `grill-with-docs` | 手動 | 磨利一份在倉庫裡的計畫（會寫 `CONTEXT.md`／ADR） |
| `to-spec` | 手動 | 對話談完了，要收斂成規格 |
| `to-tickets` | 手動 | 規格太大，要切成多個 session 的工單 |
| `implement` | 手動 | 拿著一張票開始做 |
| `handoff` | 手動 | thread 快滿了，或要分岔出去 |
| `grilling` | **代理可自動觸發** | 任何需要在動手前對齊的時候 |
| `domain-language` | **代理可自動觸發** | 出現新詞、一詞多義、難回頭的決策 |
| `tdd` | **代理可自動觸發** | 要測試先行地建一個行為 |
| `bug-loop` | **代理可自動觸發** | 東西壞了、變慢了、間歇性失敗 |
| `diff-review` | **代理可自動觸發** | commit 前要審這次改動**寫得對不對** |
| `outcome-check` | **代理可自動觸發** | 要確認一個產出**跑起來對不對**——`implement` 收尾會自動叫它，也能單獨手動叫 |

**手動** = 只有你打出名字才叫得動，代理看不見它，其他技能也叫不動它，**不佔 context**。
**代理可自動觸發** = 代理判斷相關時會自己拿起來用，其他技能也叫得動，代價是那行描述常駐 context。

背後的取捨見 [`skill-craft`](../../skill-craft/SKILL.md)「調用方式」。

---

## 四、三個實戰劇本

### 劇本 A：做一個新功能

```text
你：grill-with-docs
    └─ 代理一次問你一個問題，你逐題回答
       過程中它會自己觸發 domain-language 補 CONTEXT.md 與 ADR

你：to-spec
    └─ 產出規格，發到 flow-config.md 設定的落點

  ← 到這裡都待在同一個 context window，不要 compact

判斷：這份規格一個 session 做得完嗎？

  做得完 ──→ 你：implement
                └─ 內部驅動 tdd 一片一片紅綠
                └─ 收尾自動跑 diff-review（審 diff 寫得對不對）
                └─ 再自動跑 outcome-check（派全新 context 裁判實際操作驗收）
                └─ 過了才 commit

  做不完 ──→ 你：to-tickets
                └─ 切成曳光彈工單，標明阻擋邊
             然後每張票各開一個乾淨 session：
             你：implement（票 #01）
             你：implement（票 #02）  ← 開新 session，不要接著上一張
```

### 劇本 B：修一個難搞的 bug

```text
你：這個結算金額偶爾會少算，幫我查
    └─ 代理自動觸發 bug-loop

代理會先卡在階段 1，直到它能貼出一行「已經跑過、而且對這個 bug 亮紅燈」的指令
  ← 這是刻意的。它在拿到那條迴路之前不會開始猜原因

然後：重現 → 最小化 → 3～5 個排序過的假設（會拿來問你）
      → 埋探針 → 補回歸測試 → 清場
```

**你在這個劇本裡的角色**：階段 3 它把假設清單攤給你看時，如果你知道「#3 那塊我們昨天剛上線」，講出來——那一句話常常直接跳過一小時。

### 劇本 C：審一個分支

```text
你：diff-review
    └─ 它先問你基準點（預設是跟 main 的分岔點）
    └─ 兩個 sub-agent 平行跑：
         規範軸（引用既有 code-review 的準則與五級回饋）
         規格軸（對照原始工單，找漏做的與多做的）
    └─ 兩軸並排輸出，不混排
```

### 劇本 D：確認一個東西真的能用

```text
你：outcome-check
    這個結帳功能上禮拜做完的，幫我確認真的沒問題

    └─ 它先問你驗收條件在哪（工單、規格，或你當場講）
    └─ 派一個全新 context 的裁判——不是你自己判自己
    └─ 裁判實際操作：開網頁走一次結帳流程 / 打 API / 查訂單表
       不是重讀那次的程式碼
    └─ 逐條回報：通過 / 不通過 / 無法判定，各附證據
```

**跟 `diff-review` 的差別**：`diff-review` 讀 diff，回答「寫得對不對」；`outcome-check` 操作產出，回答「跑起來對不對」。一個只讀過程式碼、沒實際跑起來驗過的功能，`diff-review` 審過也不代表能用——這正是本劇本存在的理由。

---

## 五、Context 衛生

這組技能最容易被忽略、但影響最大的一條規則：

| 時機 | 做什麼 |
|------|--------|
| `grill-with-docs` → `to-spec` → `to-tickets` | **不要中斷**。這三步要建立在同一份思考上，中間 compact 或 clear 會讓規格跟拷問脫節 |
| 每張票開工前 | **開新 session**。上一張票的實作細節留在 context 裡只會帶偏判斷 |
| 階段與階段之間的刻意斷點 | `/compact`——留在同一段對話，讓前面的輪次被摘要 |
| thread 快滿了、或要分岔去做原型 | `handoff`——壓成檔案，**開新 session** 引用它 |

一句話記法：**`handoff` 分岔，`/compact` 接續。**

---

## 六、常見狀況

| 狀況 | 判斷與處置 |
|------|-----------|
| 打了 `grill-me` 沒反應 | 該技能是手動調用，名字要打對。仍然無效 → 代理沒讀到資料夾，回頭看「二、落地」 |
| 代理自己叫了 `tdd`／`bug-loop`，但我不想要 | 直接說「不要用 TDD，先給我一個最小可跑版本」。這幾個是模型可調用的，就是為了讓它主動拿起來用 |
| 拷問問到一半覺得太囉嗦 | 說「剩下的你自己決定，把假設列出來給我看」。它會停止逐題問，改成一次列出假設 |
| `bug-loop` 卡在階段 1 出不來 | **這通常是對的**——它在告訴你這個 bug 目前沒有可靠的重現方式。它會列出試過什麼，然後跟你要環境存取權或證物 |
| `diff-review` 說找不到規格來源 | 給它工單連結或規格檔路徑。**不要叫它「自己判斷需求是什麼」**——那等於讓它自己出題自己改考卷 |
| `outcome-check` 也找不到驗收條件 | 同上，當場給幾條可操作的判準。**不要讓寫程式的那個 agent 順手兼裁判**——那就失去獨立性了 |
| `implement` 收尾跑很久 | `outcome-check` 是實際操作（開網頁、打 API），比讀 diff 慢是正常的。連續 3 輪不過會自動停下來問你，不會無限重跑 |
| 想改某個技能的行為 | 先讀 `skill-craft`。特別注意：拷問的行為只在 `grilling` 一個地方，改那裡就好，不要去改兩個包裝層 |
| 技能太多記不住 | 叫 `skill-map` |

---

## 七、跟既有技能並用

| 你要的 | 用這個 | 不是那個，因為 |
|--------|--------|---------------|
| 審一次改動**寫得對不對** | `diff-review` | `code-review` 是判斷準則本身，`diff-review` 引用它、不重抄 |
| 驗收一個產出**跑起來對不對** | `outcome-check` | `diff-review` 讀 diff；這個實際操作，兩者互補，一次交付都跑 |
| 判斷某段程式碼**好不好** | `code-review` | 那就是準則的家 |
| 需求 → **分析報告** | `feature-analysis-skill` | `to-spec` 產的是餵給 `to-tickets` 的規格，不是給人讀的分析 |
| 需求 → **API 規格** | `restful-api-spec-writer` | `to-spec` 寫的是行為與接縫，不是介面定義 |
| 討論需求時的**回應格式** | `unified-response-format` | 那是「怎麼回話」，`grilling` 是「怎麼問話」，兩者可以同時開著 |
| 找第二個 AI 挑刺 | `gemini-redteam` | 手動觸發，且與本組正交——`to-spec` 產出的規格可以直接丟給它對抗 |

---

## 八、已知限制

⚠️ `disable-model-invocation` 確認是 Claude Code 支援的欄位，**Antigravity 是否支援未經查證**。若 Antigravity 忽略它，那 9 個手動技能會變成代理也看得到——行為仍然正確，只是多付一份上下文負載。

驗證方式：在 Antigravity 開新 session 問「有哪些技能可用」，看 `grill-me` 會不會出現在清單裡。

---
**最後更新**: 2026-08-04
**維護者**: 開發團隊
**文件版本**: v1.1
**變更記錄**（里程碑，最多 5 條）:
- v1.1 (2026-08-04): 新增 `outcome-check`（劇本 D）——`implement` 收尾自動接上，也能單獨手動叫；技能速查表、常見狀況、跟既有技能並用三處同步補上與 `diff-review` 的分工
- v1.0 (2026-08-04): 首版，收錄落地方式、技能速查表、三個實戰劇本、Context 衛生與狀況排除
