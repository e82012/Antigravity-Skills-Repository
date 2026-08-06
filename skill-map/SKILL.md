---
name: skill-map
description: 工程流程技能組的路由——忘記該用哪個技能時，問它。
disable-model-invocation: true
---

# 技能地圖 (Skill Map)

你不會記得每個技能，所以來問。

**流程**是一條穿過技能的路徑。大部分工作走同一條**主流程**，兩條**匝道**併進來。其餘的要不是獨立的，就是跑在底下的詞彙層。

> 這是**路由技能**：它只能告訴你該用哪個，**叫不動它們**——使用者可調用的技能沒有 description，除了你以外沒有東西搆得到。理由見 [`skill-craft`](../skill-craft/SKILL.md)。

## 主流程：想法 → 出貨

1. **`grill-with-docs`** — 用拷問把想法磨利。**有程式碼倉庫時從這裡開始**：它有狀態，會把學到的東西留在 `CONTEXT.md` 與 ADR 裡。（沒有倉庫？用 `grill-me`。兩個跑的是同一顆 `grilling` 原語，差別只在留不留紙本軌跡。）

2. **分岔——每個問題都能在對話裡解掉嗎？** 有問題需要「跑起來才知道」的答案（狀態機、商業邏輯、要親眼看到的 UI），就繞道做一個拋棄式原型，兩個方向都用 **`handoff`** 搭橋：`handoff` 出去 → 開新 session 做原型 → `handoff` 把學到的帶回來。

3. **分岔——這是跨多個 session 的工程嗎？**
   - **是** → **`to-spec`**（把對話收斂成規格），再 **`to-tickets`** 切成曳光彈工單，每張票標明阻擋邊。然後**每張票開一個乾淨 session** 跑 **`implement`**。
   - **否** → 直接在同一個 context 裡 **`implement`**。

   兩條路都一樣：**`implement`** 內部驅動 **`tdd`** 一片一片跑紅綠，收尾跑 **`diff-review`** 雙軸審查，再跑 **`outcome-check`** 派一個全新 context 的裁判實際操作驗收，過了才 commit。只想單獨測一個具體行為就直接叫 `tdd`；只想審一個分支就直接叫 `diff-review`；只想確認一個已完成的東西真的能用就直接叫 `outcome-check`。

### Context 衛生

步驟 1～3 待在**同一個沒有中斷的 context window** 裡——切完票之前不要 compact 或 clear。每個 `implement` 各自從乾淨的 session 開始。

如果在切票之前 context 就快撐爆，不要硬撐著在退化狀態下推進——`handoff` 之後換一條新的 thread。

## 匝道

- **東西壞了** → **`bug-loop`**。專治難搞的：一眼看不出來的、間歇性飄的、在兩個已知良好狀態之間偷偷跑進來的回歸。它在拿到一條**緊**的回饋迴路（一行已經對這個 bug 亮過紅燈的指令）之前，拒絕開始推理。

- **需要一份共同語言** → **`domain-language`**。這是 `grill-with-docs` 在背後驅動的那套紀律，也可以單獨叫：某個詞很模糊、某個詞同時指三件事、某個難以回頭的決策該被釘成 ADR 的時候。

- **確認一個東西真的做完了、能用** → **`outcome-check`**。不限於剛實作完——別人交來的東西、很久以前做的功能忽然要驗，都能單獨叫。裁判永遠是**全新 context**，不是你自己判自己。

## 詞彙層

- **`domain-language`** — 磨利專案的**領域**語言（`CONTEXT.md` 與 ADR）。
- **`skill-craft`**（+ [`GLOSSARY.md`](../skill-craft/GLOSSARY.md)）— 寫技能與改技能的詞彙。覺得某個技能不聽話、或想新增技能時讀它。

## 跨 session

- **`handoff`** — thread 滿了、或要分岔出去時，把對話壓成一份 markdown。你**不在原地繼續**，而是**開新 session 引用那個檔案**。`handoff` 分岔，`/compact` 接續。
- **`/compact`**（內建）— 留在**同一段對話**裡讓前面的輪次被摘要。用在**階段之間的刻意斷點**上；不要在階段中途 compact。

## 前置

**`setup-flow`** — 第一次跑工程流程之前先跑它，設定議題追蹤系統與領域文件配置。`to-spec`、`to-tickets`、`implement` 都假設它跑過了。

## 與既有技能的分工

| 需求 | 用這個 | 為什麼不是另一個 |
|------|--------|-----------------|
| 審查一次改動**寫得對不對** | `diff-review` | 它是**流程**（釘定點、雙軸、平行 sub-agent）；判斷準則與五級回饋在 `code-review`，`diff-review` 直接引用不重抄 |
| 驗收一個產出**跑起來對不對** | `outcome-check` | `diff-review` 讀 diff，這個實際操作（跑 API、開網頁、查資料庫）——兩者互補不互斥，一次交付兩個都跑 |
| 判斷某段程式碼好不好 | `code-review` | 那是判斷準則本身 |
| 把需求變成分析報告 | `feature-analysis-skill` | 那是分析交付物；`to-spec` 產的是給 `to-tickets` 吃的規格 |
| 把需求變成 API 規格 | `restful-api-spec-writer` | 那是介面定義；`to-spec` 是行為與接縫 |
| 討論需求時的回應格式 | `unified-response-format` | 那是**怎麼回話**；`grilling` 是**怎麼問話** |

## 延伸

- 落地方式、技能速查表、三個實戰劇本、狀況排除 → [resources/usage-guide.md](resources/usage-guide.md)
- 這套技能取自哪裡、學了什麼、刻意不學什麼 → [resources/source-analysis.md](resources/source-analysis.md)
