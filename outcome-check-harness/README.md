# Outcome Check Harness

`outcome-check`(SKILL)是寫給模型讀的指引,靠模型自願遵守——這是 Böckeler 2×2 框架裡的**前饋 Guides**。本工具把同一個概念做成**回饋 Sensor**:寫進 Claude Code 的 `Stop` hook,代碼層強制攔截,不靠模型自覺。

## 機制

```
一輪對話要結束
    │
    ▼
Stop hook 觸發（stop-outcome-check.ps1）
    │
    ├─ 目標專案沒有 .claude/outcome-check/rubric.md？ ──→ 靜默放行
    │
    ├─ 已連續 3 輪不通過？ ──→ 清空計數器，附警告放行（呼應 global-rules §8）
    │
    └─ 呼叫獨立 headless 裁判（claude -p --model haiku --output-format json）
            │
            ├─ 裁判判定通過 ──→ 清空計數器，放行
            │
            └─ 裁判判定不通過 ──→ decision:block + 具體理由，計數器 +1，逼下一輪重做
```

裁判只拿到 rubric 內容與上一輪的 `last_assistant_message`,**不給實作過程、不給推理脈絡**——這是它獨立性的來源,跟 `outcome-check` SKILL 要求「全新 context」是同一個精神,只是這次是代碼層真的另開一個 headless session,不是靠主線 agent 自覺地開 subagent。

## 安裝

```powershell
# 只對單一專案生效
pwsh -File install.ps1 -Scope project -Root <專案路徑> -DryRun   # 先預演
pwsh -File install.ps1 -Scope project -Root <專案路徑>           # 確認後執行

# 對這台機器上所有專案生效（裝一次，各專案自己開 rubric 就會啟動）
pwsh -File install.ps1 -Scope user -DryRun
pwsh -File install.ps1 -Scope user
```

裝完不會攔任何東西,要等目標專案的 `.claude/outcome-check/rubric.md` 被填入真實驗收條件才會啟動。範本已經放好,說明文字會被裁判一起讀到——寫驗收條件時盡量用條列,不要跟範本裡的操作說明混在一起（見下方「實測發現」）。

**卸載**：手動編輯 `.claude/settings.json`，從 `hooks.Stop` 陣列裡刪掉 `command` 含 `stop-outcome-check.ps1` 的那個條目；再刪掉 `.claude/hooks/stop-outcome-check.ps1` 與 `.claude/outcome-check/` 資料夾。沒有寫自動卸載腳本——這個動作頻率低，手動改一次 JSON 比再維護一支腳本划算。

## 成本

每次 Stop 都多一次 `claude -p` 呼叫，用 `haiku` 省成本，但仍是真實花費——實測單次呼叫落在 30～40 秒、US$0.07～0.11（依 rubric 長度與裁判需要讀幾個檔案而異）。**沒有 rubric 的專案完全零成本**（第一個分支就放行，不會呼叫裁判）。

## 已知限制（誠實列出）

| 項目 | 狀態 |
|---|---|
| Hook 內呼叫 `claude -p` 的遞迴/巢狀 session 行為 | 官方文件**未記載**。本腳本用環境變數 `OUTCOME_CHECK_HARNESS_ACTIVE` 自行防遞迴，不是官方保證的機制 |
| headless `claude -p` 是否有完整工具權限 | **實測確認：沒有**。裁判嘗試執行 `Get-ChildItem` 被 `permission_denials` 擋下——headless 呼叫仍受權限系統管控，不是無限制執行 |
| `type: "agent"` 這種原生 hook 型別 | 官方文件證實存在、且正是為這種用途設計的，但**沒有查到完整 schema 範例**，本工具改用已完整查證過 schema 的 `type: "command"` |
| Stop hook 的 stdin/decision 格式 | **已查證確認**：`session_id`、`transcript_path`、`last_assistant_message` 等欄位存在；`decision:"block"` 會讓對話繼續下一輪，不是真的卡住 |
| 端到端真實觸發 | 用模擬 stdin JSON 直接呼叫腳本測過四個分支（無 rubric／不通過／達上限／通過），**沒有在真實的 Claude Code Stop 事件裡跑過**——那需要一次真的對話跑到結束才會觸發，這次沒有那樣的場景可測 |

## 實測發現（寫程式當下踩過的坑）

1. **UTF-8 編碼**：`Start-Job` 呼叫外部命令時沒設 `[Console]::OutputEncoding`，裁判回傳的中文會被讀成亂碼，導致 JSON 解析失敗。已修：Job 內部顯式設定 UTF8。
2. **Markdown code fence**：裁判習慣把 JSON 包在 ` ```json ... ``` ` 裡，直接 `ConvertFrom-Json` 會失敗。已修：解析前先剝殼。
3. **裁判會把 rubric 檔案裡的操作說明也當成驗收項目**：範本裡「刪掉這份檔案 Stop hook 就不會攔」這句話，被裁判讀成「驗收條件要求這份檔案不存在」，因而多算了一條不通過的理由。不是 bug，是裁判照著給的權限主動查證——但提醒寫真實 rubric 時，把操作說明跟驗收條件分開寫，或直接整份取代掉範本文字。

## 技術依據

- Stop hook 規格、`decision`/`additionalContext` 格式：https://code.claude.com/docs/en/hooks.md
- Headless 模式與 `--model`／`--output-format`：https://code.claude.com/docs/en/headless.md 、 https://code.claude.com/docs/en/cli-reference.md
- Settings 疊加規則（project／user／local）：https://code.claude.com/docs/en/settings.md

---
**最後更新**: 2026-08-06
**維護者**: 開發團隊
**文件版本**: v1.0
**變更記錄**（里程碑，最多 5 條）:
- v1.0 (2026-08-06): 首版。實作 Stop hook + 獨立 headless 裁判 + 迭代上限，經模擬 stdin 測過四個分支（無 rubric／不通過／達上限／通過），修正編碼與 markdown fence 兩個實測 bug
