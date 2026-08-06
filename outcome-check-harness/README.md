# Outcome Check Harness

`outcome-check`(SKILL)是寫給模型讀的指引,靠模型自願遵守——這是 Böckeler 2×2 框架裡的**前饋 Guides**。本工具把同一個概念做成**回饋 Sensor**:寫進 Claude Code 的 `Stop` hook,代碼層強制攔截,不靠模型自覺。

**只裝一次,全域生效,不碰任何專案目錄。** 這是修正過的設計——第一版曾經支援「裝進單一專案」,實測發現會污染沒有 `.gitignore` 排除 `.claude/` 的專案,已經拿掉,細節見文末「設計變更記錄」。

## 機制

```
一輪對話要結束
    │
    ▼
Stop hook 觸發（stop-outcome-check.ps1，裝在 ~/.claude/hooks/）
    │
    ├─ 這個專案沒有在 ~/.claude/outcome-check-state/<專案key>/ 設定 rubric？ ──→ 靜默放行
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

**專案路徑 → 狀態目錄的對應規則**：`~/.claude/outcome-check-state/<路徑去掉冒號反斜線>-<路徑的 MD5 前 8 碼>/`。這個轉換規則同時寫在 `hooks/stop-outcome-check.ps1` 與 `set-rubric.ps1` 裡，兩邊必須完全一致——改一邊沒改另一邊，兩者就會算出不同路徑，互相找不到對方。

## 安裝

```powershell
# 只需要跑一次，對這台機器上所有專案生效
pwsh -File install.ps1 -DryRun   # 先預演
pwsh -File install.ps1           # 確認後執行
```

裝完對所有專案都是零成本待命——沒有設定 rubric 就靜默放行，不會建立、不會修改任何專案內的檔案。

## 針對某個專案啟用 / 查看 / 停用

```powershell
# 啟用：寫入驗收條件
pwsh -File set-rubric.ps1 -ProjectRoot D:\wsky\Star888Background -RubricFile .\my-rubric.md
pwsh -File set-rubric.ps1 -ProjectRoot D:\wsky\Star888Background -RubricText "- [ ] xxx"

# 查看目前狀態（驗收條件內容 + 已嘗試輪數）
pwsh -File set-rubric.ps1 -ProjectRoot D:\wsky\Star888Background -Show

# 停用（清掉驗收條件，之後 Stop hook 對這個專案靜默放行）
pwsh -File set-rubric.ps1 -ProjectRoot D:\wsky\Star888Background -Clear
```

`-ProjectRoot` 要跟 Claude Code 啟動時的工作目錄一致，路徑轉換才配得對。

## 解除安裝

```powershell
# 停用所有專案的驗收條件（不留殘留狀態）
Remove-Item -Recurse -Force "$HOME\.claude\outcome-check-state"
```

再手動編輯 `~/.claude/settings.json`，從 `hooks.Stop` 陣列裡刪掉 `command` 含 `stop-outcome-check.ps1` 的那個條目，並刪掉 `~/.claude/hooks/stop-outcome-check.ps1`。沒有寫自動解除安裝腳本——這個動作頻率低，手動改一次 JSON 比再維護一支腳本划算。

## 成本

每次 Stop 都多一次 `claude -p` 呼叫，用 `haiku` 省成本，但仍是真實花費——實測單次呼叫落在 30～40 秒、US$0.07～0.11（依 rubric 長度與裁判需要讀幾個檔案而異）。**沒有設定 rubric 的專案完全零成本**（第一個分支就放行，不會呼叫裁判）。

## 已知限制（誠實列出）

| 項目 | 狀態 |
|---|---|
| Hook 內呼叫 `claude -p` 的遞迴/巢狀 session 行為 | 官方文件**未記載**。本腳本用環境變數 `OUTCOME_CHECK_HARNESS_ACTIVE` 自行防遞迴，不是官方保證的機制 |
| headless `claude -p` 是否有完整工具權限 | **實測確認：沒有**。裁判嘗試執行 `Get-ChildItem` 被 `permission_denials` 擋下——headless 呼叫仍受權限系統管控，不是無限制執行 |
| `type: "agent"` 這種原生 hook 型別 | 官方文件證實存在、且正是為這種用途設計的，但**沒有查到完整 schema 範例**，本工具改用已完整查證過 schema 的 `type: "command"` |
| Stop hook 的 stdin/decision 格式 | **已查證確認**：`session_id`、`cwd`、`last_assistant_message` 等欄位存在；`decision:"block"` 會讓對話繼續下一輪，不是真的卡住 |
| 端到端真實觸發 | 用模擬 stdin JSON 直接呼叫腳本測過完整鏈路（無 rubric／不通過／達上限／通過／全域路徑正確對應），**沒有在真實的 Claude Code Stop 事件裡跑過**——那需要一次真的對話跑到結束才會觸發 |

## 實測發現（寫程式當下踩過的坑）

1. **UTF-8 編碼**：`Start-Job` 呼叫外部命令時沒設 `[Console]::OutputEncoding`，裁判回傳的中文會被讀成亂碼，導致 JSON 解析失敗。已修：Job 內部顯式設定 UTF8。
2. **Markdown code fence**：裁判習慣把 JSON 包在 ` ```json ... ``` ` 裡，直接 `ConvertFrom-Json` 會失敗。已修：解析前先剝殼。
3. **裁判會把 rubric 檔案裡的操作說明也當成驗收項目**：如果 rubric 裡混了操作說明文字（例如「刪掉這份檔案就會停用」），裁判可能會把這句話也當成驗收條件的一部分去檢查。寫 rubric 時盡量只放純粹的驗收條件，不要混操作說明。
4. **第一版把 rubric／計數器放在專案目錄裡，會污染沒有 `.gitignore` 排除的專案**：拿真實專案測試時發現這些檔案直接進了 `git status` 的暫存區。已修：全部搬到 `~/.claude/outcome-check-state/`，專案端零接觸——見下方「設計變更記錄」。

## 設計變更記錄

第一版（2026-08-06 上午）用 `install.ps1 -Scope project|user` 兩種安裝範圍，project 範圍會在目標專案寫入 `.claude/settings.json`、`.claude/hooks/`、`.claude/outcome-check/rubric.md`。實際對 `Star888Background` 測試後發現：這個專案的 `.claude/` 沒有被 `.gitignore` 排除，剛裝完這些檔案就出現在 `git status` 的暫存區——等於工具本身在幫使用者製造一次意外的 commit。

問題不只是「project 範圍不該存在」，而是**就算改用 user 範圍裝 hook，rubric 檔案本身仍然被設計成要放在專案目錄裡**（`<專案>/.claude/outcome-check/rubric.md`），一樣會被 commit 進去。真正的修法是把 rubric 與計數器都搬出專案，存在使用者本機、用專案路徑對應——這就是現在這版的設計。`install.ps1` 現在只做一件事：把 hook 裝進 `~/.claude/settings.json`，永遠不建立任何專案內檔案；`set-rubric.ps1` 是新增的工具，專門處理「對某個專案啟用/查看/停用」，一樣只寫使用者本機的狀態目錄。

## 技術依據

- Stop hook 規格、`decision`/`additionalContext` 格式：https://code.claude.com/docs/en/hooks.md
- Headless 模式與 `--model`／`--output-format`：https://code.claude.com/docs/en/headless.md 、 https://code.claude.com/docs/en/cli-reference.md
- Settings 疊加規則（project／user／local）：https://code.claude.com/docs/en/settings.md

---
**最後更新**: 2026-08-06
**維護者**: 開發團隊
**文件版本**: v2.0
**變更記錄**（里程碑，最多 5 條）:
- v2.0 (2026-08-06): 拿掉 project 安裝範圍，rubric 與計數器全部搬到 ~/.claude/outcome-check-state/，專案端零接觸——修正實測對 Star888Background 造成的專案污染；新增 set-rubric.ps1 管理單一專案的啟用/查看/停用
- v1.0 (2026-08-06): 首版。實作 Stop hook + 獨立 headless 裁判 + 迭代上限，經模擬 stdin 測過四個分支，修正編碼與 markdown fence 兩個實測 bug
