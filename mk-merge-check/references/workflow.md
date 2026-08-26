# 操作流程：四階段完整步驟

> 搭配 `SKILL.md` 的摘要使用。本檔補齊 git 分支維度、指令與環境需求。

## 比對基準：git 分支

整併在**分支**上進行，比對是分支對分支：

| 情境 | 整併側 | 基準側 | 方式 |
|------|--------|--------|------|
| MK 站自身 | MKBackground `merge/ou/{領域}` | MKBackground `main` | 同 repo，`git diff` |
| 其他站 | MKBackground `merge/ou/{領域}` | 該站 repo `main` | 跨 repo，比工作樹 |

- 整併分支命名為 `merge/ou/{領域}`（如 `merge/ou/dataland`、`merge/ou/config`、`merge/ou/game`）。Phase 0 要先確認**這次比的是哪個領域分支**。
- MKBackground 已把部分原專案掛成 remote（如 `m911/main`、`381/main`），跨 repo 比對時可善用，但**基準真相以各站獨立 repo 的 `main` 為準**。
- 動手 checkout／建 worktree 前，先確認工作樹乾淨（`git status`），避免弄丟未提交變更。跨分支跑動態驗證建議用 **git worktree**，不要在原工作樹反覆 checkout。

## Phase 0 — 定位

1. 確認入口模式：**端點模式**（給路由＋站）或**功能模式**（給關鍵字）。不明確就問使用者一題。
2. 確認整併領域分支名稱（`git -C d:/wsky/MKBackground branch --list 'merge/ou/*'`）。
3. 端點模式：確認路由 URI ＋ HTTP method（如 `GET dataland/origin`）與目標站（如 `m911TWPCBackground`）。
4. 功能模式：用關鍵字掃出 MK 與該站的相關類清單：
   ```bash
   grep -rl "DataLand" d:/wsky/MKBackground/app | sort
   grep -rl "DataLand" d:/wsky/m911TWPCBackground/app | sort
   ```

## Phase 1 — 靜態比對

### MK 站自身（同 repo 分支 diff，最乾淨）

```bash
git -C d:/wsky/MKBackground diff main..merge/ou/dataland -- app/Http/Controllers/DataLandController.php app/Services/DatalandReports
```
這直接顯示整併對 MK 自己改了什麼。逐段判讀是否僅為策略模式重構。

### 其他站（跨 repo，呼叫鏈比對）

方法名兩邊不同，用路由錨點法逐層追：

1. 兩邊各自解析路由 → controller@method（解析器怎麼寫見 `writing-static-tools.md`；MK 側 `GET dataland/origin` → `origin`，m911 側 → `originCagentcheckList`）。
2. MK 側再解出實際報表類：讀 `config/clients/911twpc.php` 的 `versions.dataland.origin`（`origin_v2`）→ 對 `DataLandReportResolver::REGISTRY['origin']['origin_v2']` → `OriginV2Report::getCagentcheckList`。
3. 打開兩邊實際執行的檔，逐層 diff：Controller → Report/Service → Repository → Model/SQL。
4. 比對重點：查詢的表與 join、where／group by 條件、參與運算的欄位、回應資料 shape、商業邏輯分支、邊界處理（查無資料、日期預設）。**逐項語意比對，不用行數／字串數量代替**（見 `rigor-and-antipatterns.md`）。

## Phase 2 — 動態驗證（繞過 auth，比最終輸出）

### 原理

`scripts/templates/probe.php` 在目標專案內 boot Laravel，**不經 router／middleware**，直接：
1. 設 `PROJECT_CODE`（讓 MK 扮演目標站；原專案不需要）。
2. 用查詢參數建一個 `Illuminate\Http\Request`。
3. 若邏輯需登入者，用 `auth()->setUser($user)` 手動注入（繞過 Sanctum token）。
4. 直接呼叫目標 controller method 或 service／報表類方法，取得**回傳資料**（jsonResponse 包裝前或解包後皆可，兩邊取同一層）。
5. dump 成正規化 JSON（key 排序、浮點固定位數、時間欄位遮罩）。

### 步驟

流程（工具由 AI 依 `writing-the-probe.md` 現建，放在各目標專案的 `tmp/{任務名}/` 下）：

0. **前置硬閘門**：先比對兩邊 `.env` 的 `DB_CONNECTION/HOST/PORT/DATABASE/USERNAME` 是否逐項相同（連同一個 DB）。不一致就停，先對齊 DB——否則測出的差異全是資料差異，無意義。細節見 `writing-the-probe.md`。
1. 在 MK 整併分支的 worktree 內，建 probe 於 `<MK-worktree>/tmp/origin-diff/probe.php`，設 `PROJECT_CODE=911twpc`，餵相同參數，匯出 `tmp/origin-diff/mk_origin.json`。
2. 在原專案 `m911TWPCBackground/tmp/origin-diff/` 建對應 probe，餵**相同參數**，匯出 `m911_origin.json`。
3. 將兩份 JSON 做**逐鍵逐值正規化深比對**（不是比檔案大小或行數，見 `rigor-and-antipatterns.md`），產出輸出差異報告。

### 環境需求與 fixture 對齊（誠實面對）

動態驗證要「同輸入」才有意義，這需要：
- 兩專案都能 boot（vendor 完整、`.env` 可連測試 DB）。
- **輸入資料對齊**：最可靠是兩邊指向**同一份 seeded 測試資料**。可行策略（擇一）：
  - (a) 共用測試 DB：兩專案 `.env` 指向同一個 seeded DB（若 schema 相容）。
  - (b) 匯出真實資料快照，各自匯入自己的測試 DB。
  - (c) 純邏輯層驗證：對報表類餵**相同的合成輸入列**（stub 掉資料抓取），只比運算與組裝邏輯。
- 若環境未就緒，Phase 2 先擱置並明確標註「動態未驗證」，**不得**用靜態結果冒充動態通過（呼應全域 §1）。

## Phase 3 — 分級

見 `severity-rubric.md`。對每個差異寫明「核心邏輯是否實質相異」。

## Phase 4 — 修正 MK 整併

只動 MK 整併分支，不動原專案：

1. 定位該修的檔（報表類／`DataLandReportResolver::REGISTRY`／`config/clients/{code}.php`）。
2. **動手前**：`git -C <MK> status` 確認乾淨 → commit 或備份（scratchpad `backup/{任務}/`）。
3. 最小改動修正。
4. 重跑 Phase 2，確認該站輸出收斂。
5. **回歸**：查 `site-map.md`，該報表版本若被多站共用，逐站重跑動態驗證。
6. 產出修正記錄（檔／原因／驗證前後輸出）。

## 產物放置

- **所有驗證工具（probe、解析器、diff 腳本）與其產物（匯出 JSON、差異報告）→ 目標專案內 `tmp/{任務名}/`**。探針要在該專案內 boot 才吃得到其 vendor／config，故一律落該專案 tmp。任務完成後由使用者決定清理。
- MK 修正的備份 → scratchpad `backup/{任務名}/`，驗證通過即刪。

---
**最後更新**: 2026-08-26
**維護者**: 開發團隊
**文件版本**: v1.0
**變更記錄**（里程碑，最多 5 條）:
- v1.0 (2026-08-26): 初版，納入 git 分支比對維度（MK 整併分支 vs main／各站 main）、四階段步驟、動態驗證環境需求與 fixture 對齊策略
