# sync-skills.ps1 — 全局準則與技能同步工具

把本倉庫同步到各 AI 代理的設定目錄。**本倉庫是唯一真實來源，目標端全部是產生物**——改規則一律改這裡再跑同步，不要直接改目標端。

## 用法

```powershell
# 互動選單（人工執行）
pwsh -File tools\sync-skills.ps1

# 直接指定（自動化）
pwsh -File tools\sync-skills.ps1 -Mode all -Target all
```

### 參數

| 參數 | 值 | 說明 |
|------|-----|------|
| `-Mode` | `rules` / `skills` / `all` | 同步什麼。省略則顯示選單 |
| `-Target` | `claude` / `gemini` / `codex` / `all` | 同步到哪個代理，預設 `all` |
| `-Root` | 路徑 | 來源倉庫根目錄，預設為本腳本的上一層 |
| `-DryRun` | switch | 只印出將執行的動作，不寫入 |
| `-AllowUnverified` | switch | 允許同步路徑未經實證的目標（見下） |

**第一次使用先跑 `-DryRun`**，確認落點正確再實際執行。

## 同步落點

| 代理 | 全局準則 | 參考知識 | 技能 | 路徑狀態 |
|------|---------|---------|------|---------|
| Claude Code | `~/.claude/CLAUDE.md` | `~/.claude/resources/` | `~/.claude/skills/<name>/` | 已實證 |
| Gemini / Antigravity | `~/.gemini/GEMINI.md`（上限 23,999 bytes） | `~/.gemini/resources/` | `~/.gemini/config/skills/<name>/` | 已實證 |
| Codex | `~/.codex/AGENTS.md` | `~/.codex/resources/` | `~/.codex/skills/<name>/` | ⚠️ **未實證** |

**⚠️ Codex 路徑未經實證**：本機未安裝 Codex，表中路徑屬暫定值。預設會跳過並回退出碼 3（明確指定 `-Target codex` 時），確認實際路徑後修改 `sync-skills.ps1` 頂端的 `$TargetMap`，或加 `-AllowUnverified` 強制執行。

## 規則檔大小上限

**Antigravity 的規則檔載入上限為 23,999 bytes，超過的部分會被靜默截斷**——尾端章節不會進入 context，而代理不一定會主動說它讀不到。

同步時會自動檢查並分三級回報：

| 狀況 | 輸出 |
|------|------|
| 超過上限 | `[WARN]` 標明超出幾 bytes，摘要表加註 `⚠️ 超標` |
| 餘裕不足 2,000 bytes | `[WARN]` 提醒接近邊緣 |
| 正常 | 印出 `大小 / 上限`與餘裕 |

Claude Code 觀測到 26,357 bytes 的規則檔完整載入未截斷，上限位置未知，設為不檢查。Codex 未安裝，同樣不檢查。測得實際數值後填進 `$TargetMap` 的 `RulesSizeLimit`。

**Antigravity 的技能路徑依據**：官方說明文件（`~/.gemini/antigravity/builtin/skills/agy-customizations/SKILL.md`）指明全域 customization root 為 `~/.gemini/config/`，技能放其下的 `skills/`。舊路徑 `~/.gemini/antigravity/global_skills/` 已於 2026-05 遷移淘汰。

**不複製的替代方案**：Antigravity 支援用 `skills.json` 註冊外部路徑。在 `~/.gemini/config/skills.json` 寫入以下內容，即可讓 Antigravity 直接讀本倉庫，不需要跑技能同步：

```json
{
  "entries": [
    { "path": "D:/AntiGravity-Skill", "exclude": ["tools", "global-rules"] }
  ]
}
```

### 兩個落點設計

- **參考知識固定放在規則檔的同層 `resources/`**，因為 `SKILL.md` §12.2 的路徑是相對於規則檔所在目錄；放別的地方會讓那些指向全部失效。
- **`global-rules` 只走全局準則通道，不進技能目錄**。它已經是每個 session 全載的規則本體，再放一份到技能目錄會讓同一套條文被載入兩次。

## 退出碼

| 碼 | 意義 | 呼叫端該怎麼辦 |
|----|------|--------------|
| 0 | 成功（含 `-Target all` 時部分目標因未安裝而跳過） | 讀摘要表確認每個目標的狀態 |
| 1 | 參數驗證失敗，或未預期的例外 | 看錯誤訊息修正 |
| 2 | 互動選單輸入了無效選項 | 重跑並輸入 0–3 |
| 3 | 明確指定的目標不存在或路徑未實證 | 確認該代理已安裝，或修改 `$TargetMap` |
| 4 | `-Root` 的路徑分隔符被 shell 吃掉 | 路徑加引號，或改用正斜線 |
| 5 | 來源倉庫路徑不存在，或找不到 `global-rules/SKILL.md` | 用 `-Root` 指定正確的倉庫根目錄 |
| 6 | 備份失敗 | 已中止且未做任何寫入，檢查暫存區權限與空間 |

## 備份

覆蓋前會把目標端的既有內容備份到 `%TEMP%\antigravity-sync-backup\<時間戳>\`，執行結束時印出完整路徑。

**刻意不自動刪備份**——工具無法判斷同步結果是否正確，確認無誤後請自行刪除。

## 刻意不做什麼

讀者需要知道工具的沉默不代表沒問題：

- **不刪除目標端多出來的檔案**。只做覆蓋與新增，不做鏡像。目標端若有本倉庫已移除的舊技能，會留在原地，需自行清理。
- **不驗證同步後是否真的被代理載入**。腳本只確保檔案到位；準則有沒有生效要開新 session 實測（見主 README 的驗證步驟）。
- **不處理 `.lnk` 捷徑**。偵測到會警告，但不會刪——是否移除舊捷徑由你決定。
- **不檢查內容正確性**。只比對檔案存在與否，不看 SKILL.md 寫了什麼。
- **不同步沒有 `SKILL.md` 的資料夾**，執行時會列出被排除的清單。
- **中途失敗不會自動回滾**。寫入前一定有備份，但若在多個目標之間中斷，先完成的目標會保持已覆蓋狀態；錯誤訊息會印出備份路徑供人工還原。

## 驗收紀錄

| 檢查項目 | 結果 |
|---------|------|
| 預演流程（`-Mode all -Target all -DryRun`） | 通過，12 個技能 + 準則落點正確 |
| **實際寫入**（`-Mode rules -Target claude`） | 通過，`CLAUDE.md` 與來源 SHA256 一致，`resources/` 五份到齊 |
| **含子目錄的遞迴複製** | 通過，來源與目標檔數一致 |
| 路徑被 shell 吃掉 | 回 exit 4 |
| 明確指定未實證目標 | 回 exit 3，未做任何寫入 |
| 來源路徑不存在 | 回 exit 5 |
| 無效參數值 | 回 exit 1（PowerShell ValidateSet 攔截） |
| 未預期中斷 | `trap` 收斂為 exit 1，並印出備份路徑 |

**`-DryRun` 不會執行到寫入邏輯**，只驗預演不等於驗過工具——每次改動寫入相關的程式碼，必須實跑一次真實同步。

---
**最後更新**: 2026-07-23
**維護者**: 開發團隊
**文件版本**: v1.0
**變更記錄**（里程碑，最多 5 條）:
- v1.0 (2026-07-23): 首版，建立跨代理同步工具（Claude Code／Gemini Antigravity／Codex），含退出碼定義、備份機制與刻意不做的範圍說明
