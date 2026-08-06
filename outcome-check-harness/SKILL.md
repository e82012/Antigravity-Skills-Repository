---
name: outcome-check-harness
description: 把 outcome-check 從「提示詞建議」升級成「代碼強制」——裝一個 Stop hook，agent 想跳過驗收也跳不過。當使用者明確要求「幫我把驗收做成真的會擋住的」「裝一個真正的 harness」「這個要強制驗收，不能自己說過了就過了」時使用。
disable-model-invocation: true
---

# Outcome Check Harness

`outcome-check`(SKILL)是**Guides**——寫給模型讀的指引,靠模型自願遵守。本技能是**Sensor**——寫進 Claude Code 的 `Stop` hook,是代碼層的強制攔截,模型想跳過也跳不過。差別見 [`skill-craft`](../skill-craft/SKILL.md) 或直接讀 [README.md](README.md) 的第一段。

## 什麼時候用

**安裝(第一次跑 `install.ps1`)只在使用者明確要求時做。** 這會修改 `~/.claude/settings.json`(持續性配置),依安全規則需要明確許可,不能因為「這個任務聽起來需要嚴格驗收」就自己動手裝。

只裝一次,對這台機器上所有專案生效,**完全不碰任何專案目錄**——第一版曾經支援裝進單一專案,實測會污染沒有 `.gitignore` 排除 `.claude/` 的專案,已經拿掉,細節見 [README.md](README.md) 的「設計變更記錄」。

## 使用方式

1. **讀 [README.md](README.md)** 了解機制、成本、已知限制——這不是零成本的東西,每次 Stop 都會多花一次 API 呼叫。
2. **裝一次(如果還沒裝過)**:

   ```powershell
   pwsh -File outcome-check-harness/install.ps1 -DryRun   # 先預演給使用者看
   pwsh -File outcome-check-harness/install.ps1           # 確認後執行
   ```

3. **對想啟用的專案設定驗收條件**(這一步不需要重新安裝,也不會碰專案目錄):

   ```powershell
   pwsh -File outcome-check-harness/set-rubric.ps1 -ProjectRoot <專案路徑> -RubricText "- [ ] xxx"
   ```

4. **提醒使用者**:沒設定 rubric 的專案永遠零成本靜默放行;設定後下一次 Stop 就會開始被裁判驗收。寫驗收條件時只放純粹的判準,不要混操作說明——實測發現裁判會把說明文字也當成驗收項目的一部分去檢查。

## 完成判準

`install.ps1` 跑完 exit code 0,且沒有在任何專案目錄裡建立檔案(這是硬性要求,建了就是回退到第一版的錯誤設計);`set-rubric.ps1 -Show` 對目標專案能看到剛寫入的驗收條件。
