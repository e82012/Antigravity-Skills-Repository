---
name: outcome-check-harness
description: 把 outcome-check 從「提示詞建議」升級成「代碼強制」——裝一個 Stop hook，agent 想跳過驗收也跳不過。當使用者明確要求「幫我把驗收做成真的會擋住的」「裝一個真正的 harness」「這個要強制驗收，不能自己說過了就過了」時使用。
disable-model-invocation: true
---

# Outcome Check Harness

`outcome-check`(SKILL)是**Guides**——寫給模型讀的指引,靠模型自願遵守。本技能是**Sensor**——寫進 Claude Code 的 `Stop` hook,是代碼層的強制攔截,模型想跳過也跳不過。差別見 [`skill-craft`](../skill-craft/SKILL.md) 或直接讀 [README.md](README.md) 的第一段。

## 什麼時候用

**只在使用者明確要求時安裝。** 這會修改目標專案的 `.claude/settings.json`(持續性配置),依安全規則需要明確許可,不能因為「這個任務聽起來需要嚴格驗收」就自己動手裝。

## 使用方式

1. **讀 [README.md](README.md)** 了解機制、成本、已知限制——這不是零成本的東西,每次 Stop 都會多花一次 API 呼叫。
2. **確認安裝範圍**:`project`(只對當前專案生效)還是 `user`(對這台機器所有專案生效)。使用者沒說清楚就問,不要自己選——這是一個會影響其他專案行為的決定。
3. **跑安裝腳本**:

   ```powershell
   pwsh -File outcome-check-harness/install.ps1 -Scope project -Root <目標專案路徑> -DryRun
   ```

   先 `-DryRun` 給使用者看過要動什麼,確認後拿掉 `-DryRun` 執行。

4. **提醒使用者**:裝完不會立刻攔任何東西——要等 `.claude/outcome-check/rubric.md`(項目級)寫入真實驗收條件才會啟動。範本檔案已經幫你放好,裡面的說明文字自己會被裁判讀到,寫驗收條件時避免跟範本裡的操作說明混在一起(實測發現裁判會把「刪掉這個範例」這句話也當成驗收項目的一部分去檢查)。

## 完成判準

安裝腳本跑完 exit code 0;`.claude/settings.json` 裡看得到新增的 `hooks.Stop` 條目,且既有設定沒有被覆蓋掉(跑一次 `-DryRun` 或裝完後讀一次檔案確認);使用者知道範本 rubric 需要自己填才會生效。
