# mk-merge-check

專責檢查「整併基底 **MKBackground**」與 13 個原版獨立專案之間，**程式碼內容**與**最終輸出結果**的差異，並據以**修正 MK 整併**的 skill。

## 這隻 skill 解決什麼

MKBackground 把 13 站的邏輯用策略模式（config 分派）整併成一套碼。整併後它跟原專案**結構本來就不同**，所以不能用「檔案 diff／方法名對照」來判斷對錯。真正要驗的是：**同一支端點、同一組輸入，整併後的最終輸出跟原版一不一樣**。

- 輸出逐值一致 → 通過（哪怕架構全變）。
- 輸出不一致且非刻意 → 整併漏洞，回頭修 MK。

## 檔案結構

```
mk-merge-check/
  SKILL.md                          技能入口：四階段流程、硬性紀律
  README.md                         本檔
  references/
    architecture.md                 整併機制：PROJECT_CODE 扮演、Resolver 分派、路由錨點法
    site-map.md                     站台 ↔ PROJECT_CODE ↔ 原專案 ↔ 版本 對照（已查證）
    workflow.md                     四階段完整步驟 + git 分支比對維度
    rigor-and-antipatterns.md       ★ 嚴謹比對規則與淺層反模式（寫比對工具前必讀）
    severity-rubric.md              差異三級分級判準
    writing-static-tools.md         如何寫靜態比對工具（路由／版本解析、呼叫鏈對照）
    writing-the-probe.md            如何寫動態驗證探針（boot + 繞 auth + 正規化深比對）
```

## 設計原則

- **不預先寫死驗證工具**：驗證／測試工具由使用 skill 的 AI 依當下端點現建，放**目標專案的 `tmp/{任務名}/`** 下（探針要在該專案內 boot 才吃得到其 vendor／config）。references 只給規則與帶註解的骨架範本。
- **比對走 git 分支**：MK 站比 `merge/ou/{領域}` vs MK `main`；其他站比 MK `merge/ou/{領域}` vs 該站 repo `main`。
- **嚴謹驗證**：禁用行數／字串數量／筆數等淺層代理指標；程式碼比語意、輸出比正規化後逐鍵逐值深比對、全量不抽樣。

## 快速上手

在對話中觸發（如「用 mk-merge-check 比對 dataland/origin，MK vs m911」），AI 會依 SKILL.md 走：定位 → 靜態比對 → 動態驗證 → 分級 →（有漏洞則）修正 MK → 重驗收斂。

---
**最後更新**: 2026-08-26
**維護者**: 開發團隊
**文件版本**: v1.0
**變更記錄**（里程碑，最多 5 條）:
- v1.0 (2026-08-26): 初版交付說明
