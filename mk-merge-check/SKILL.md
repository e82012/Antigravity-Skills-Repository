---
name: mk-merge-check
description: 專責檢查「整併基底 MKBackground」與 13 個原版獨立專案之間，程式碼內容與最終輸出結果的差異，並據以修正 MK 整併。以路由 URI 為錨點（方法名稱兩邊不一致，不能對名字）比對整條呼叫鏈，動態驗證繞過 HTTP/token auth、直接呼叫 service 層比對最終結果。當使用者說「檢查整併差異」「MK 跟原專案有沒有不一樣」「比對 dataland/origin」「掃某功能在各站的差異」「修正整併」時，使用本技能。
---

# MK 整併差異檢查與修正 (MK Merge Diff Check & Remediation)

**乾淨地整併錯邏輯，跟保留原邏輯但架構重寫，是兩件不同的事。** 整併版 MKBackground 用策略模式（config 分派）把 13 站的邏輯收進一套碼，所以它跟原專案**結構本來就會不同**——這是預期的。真正要抓的是：**同一支端點、同一組輸入，整併後的最終輸出跟原版一不一樣**。輸出一致就算通過（哪怕架構全變）；輸出不一致才是整併漏洞，要修 MK。

本技能專責兩件事：
1. **檢查** — 內容（呼叫鏈結構）＋ 輸出結果 兩軸差異。
2. **修正** — 把判定為「整併漏洞」的差異，回頭修 MK 的整併碼，再驗證收斂。

## 一定要先讀懂的整併架構

整併機制的細節見 `references/architecture.md`，這裡是最低限度心智模型：

- **MK 靠 `env('PROJECT_CODE')` 扮演任一站**。設 `PROJECT_CODE=911twpc`，MK 就載入 `config/clients/911twpc.php`，`DataLandReportResolver` 據 `config('project.versions.dataland.origin')` 選出對應報表類（如 `origin_v2` → `OriginV2Report`）。
- **同一支路由，兩邊方法名稱不一樣**。`GET dataland/origin` 在 MK 打到 `DataLandController::origin()`，在 m911 打到 `DataLandController::originCagentcheckList()`。**絕不能用方法名對方法名比對**，會直接錯位。
- **唯一穩定錨點是路由 URI ＋ HTTP method**。永遠從 `routes/api.php` 的 URI 出發，在兩邊各自解析它實際打到哪。

站台 ↔ `PROJECT_CODE` ↔ 原專案目錄 ↔ 版本 的對照表見 `references/site-map.md`（已逐項查證來源）。

## 四階段流程

完整操作步驟見 `references/workflow.md`。摘要：

### Phase 0 — 定位

先決定要比什麼，兩種入口：

- **端點模式**：給一支路由（如 `GET dataland/origin`）＋ 一個目標站（如 `m911TWPCBackground`）。比 MK 扮演該站時，這支端點與原專案的差異。
- **功能模式**：給一個功能關鍵字（如 `DataLand`），列出 MK 與各站所有相關類（Controller / Services / Repository / Model / Report），逐一比對，產出差異矩陣。

**比對基準是 git 分支**：整併在分支上做。MK 站自身 = MKBackground `merge/ou/{領域}` vs MKBackground `main`（同 repo）；其他站 = MKBackground `merge/ou/{領域}` vs 該站 repo `main`（跨 repo）。定位時先確認這次比的是哪個 `merge/ou/{領域}` 分支。跨分支跑動態驗證用 git worktree，不在原工作樹反覆 checkout。

不確定要哪種、或路由參數不明時，先問使用者一個問題釐清，不要猜。

### Phase 1 — 靜態比對（讀碼，繞不過的地基）

以路由 URI 為錨點，在 MK 與原專案各自往下解析整條呼叫鏈，逐層 diff：

```
MK:   routes/api.php ─URI→ Controller@method ─resolver→ 報表類@method ─→ Repository ─→ Model/SQL
原版: routes/api.php ─URI→ Controller@method ─→ Service ─→ Repository ─→ Model/SQL
```

**驗證工具由使用 SKILL 的 AI 依當下端點現建**，不預先寫死。怎麼建、骨架長怎樣、要滿足哪些規則，見 `references/writing-static-tools.md`（含路由解析器與版本解析器的範本骨架）。

比對重點：SQL（表、join、where、group by）、參與運算的欄位、回應資料 shape、商業邏輯分支。判準見 `references/severity-rubric.md`。

### Phase 2 — 動態驗證（繞過 auth，比最終輸出）

**這是「驗出真實差異」的核心。** 靜態讀碼會漏掉執行期行為，所以要實跑。

驗證探針同樣**由使用 SKILL 的 AI 依端點現建**。撰寫規則與帶註解的骨架範本見 `references/writing-the-probe.md`，原理摘要：

- **前置硬閘門**：跑 probe 前**先確認兩邊 `.env` 的 DB 設定指向同一個資料庫**（`DB_CONNECTION/HOST/PORT/DATABASE/USERNAME` 逐項相同）。連不同 DB 讀到不同資料，輸出必然不同、毫無意義——這是假差異的頭號來源。不一致就停，先對齊 DB 再跑。
- probe 在目標專案內 boot Laravel、設好 `PROJECT_CODE`、**直接建 `Request` 呼叫目標 controller method**（不經 router／middleware／Sanctum，天然繞過 token auth），把回傳資料 dump 成正規化 JSON。
- 兩邊餵**相同輸入**（相同 query params ＋ 對齊的 fixture 資料），各自匯出 JSON，再 diff 兩份最終輸出。

動態驗證需要各專案可 boot ＋ 兩邊 DB 對齊，DB 前置檢查、環境需求與 fixture 對齊策略見 `references/writing-the-probe.md` 與 `references/workflow.md`。環境未就緒時明確標「動態未驗證」，不得用靜態冒充。

### Phase 3 — 分級

每個差異歸三類（判準見 `references/severity-rubric.md`）：

| 級別 | 意義 | 處置 |
|------|------|------|
| ✅ 等價重構 | 架構不同但輸出一致 | 記錄，不動 |
| ⚠️ 可接受差異 | 整併刻意合併／簡化，輸出有小差但有理由 | 記錄並**明確說明理由** |
| ❌ 整併漏洞 | 輸出不一致或商業邏輯被改錯 | **進 Phase 4 修正** |

務必對每個差異寫清楚「核心邏輯是否實質相異」，不要只說「有差」。

### Phase 4 — 修正 MK 整併

針對 ❌ 項目，回頭修 **MK 側**的整併碼（不是改原專案）：

1. 定位該修的檔：報表類（`app/Services/DatalandReports/*Report.php`）／resolver 分派表（`DataLandReportResolver::REGISTRY`）／站台 config（`config/clients/{code}.php`）。
2. 依全域 §4.1 安全鐵則：**動手前先 git commit 或備份**（備份放 scratchpad `backup/{任務名}/`），最小改動。
3. 重跑 Phase 2 動態驗證，確認該站輸出收斂到與原版一致。
4. **回歸檢查**：同一份報表類可能被多站共用（如 `origin_v1` 被 mk／sanbayi／zunlian 共用），改它要重跑**所有共用站**的動態驗證，避免修一站壞另一站。共用關係查 `references/site-map.md`。
5. 產出修正記錄（改了哪個檔、為什麼、驗證前後輸出）。

## 驗證工具與產物放置

**使用 SKILL 的 AI 依端點現建的所有驗證／測試工具（probe、解析器、diff 腳本）與其產物（匯出 JSON、差異報告），一律放在「目標專案」的 `tmp/{任務名}/` 下**（如 `d:/wsky/m911TWPCBackground/tmp/origin-diff/`）。任務名用 kebab-case。理由：探針要在該專案內 boot 才吃得到它的 vendor／config。SKILL 本體檔案不落在任何受測專案內。

- 交付報告本體只寫「現在的差異結論」，遵循全域 §10 文件撰寫準則。
- 每支端點／每個功能固定產出：**靜態差異 ＋ 動態差異 ＋ 分級 ＋（若修正）修正記錄**。

## 硬性紀律（呼應全域準則）

- **嚴謹比對，禁止淺層代理指標**：絕不用「字串數量、行數、字元數、match 次數、檔案大小」這類淺層計數來判定「相同／不同」——它們會給假訊號（行數一樣不代表邏輯一樣；輸出筆數一樣不代表每筆值一樣）。比對一律做到**語意／結構層級**：程式碼比 AST／逐方法邏輯，輸出比**逐鍵逐值**的正規化深比對。完整反模式清單與正解見 `references/rigor-and-antipatterns.md`，**動筆寫任何比對工具前必讀**。
- **禁止方法名對方法名**：一律路由 URI 錨點。名字對得上是巧合，不是依據。
- **A 依賴 B 三步查證（§1.3）**：宣稱「MK 的 origin 對應 m911 的 originCagentcheckList」前，要打開 `routes/api.php` 看到那一行 `Route::get('/origin', ...)`，並在兩邊都追到實際執行的那一行，才算數。
- **輸出一致優先於結構一致**：策略模式造成的結構差異不是缺陷。判定缺陷的唯一標準是最終輸出逐值一致。
- **修正只動 MK**：原專案是基準真相，不改；除非查證出原專案本身就有 bug，那要單獨向使用者提報，不自行修。
