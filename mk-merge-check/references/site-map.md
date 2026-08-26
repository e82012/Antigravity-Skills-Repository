# 站台對照表：PROJECT_CODE ↔ 原專案 ↔ 版本

> 對照關係逐項查證自 MKBackground 各 `config/clients/{code}.php` 的 docblock 與 `versions.dataland`。
> 依據：`config/clients/*.php`（各檔開頭註解自述對應站台）。

## 站台 ↔ 原專案目錄

| PROJECT_CODE | 原專案目錄 (d:\wsky\) | 備註 |
|---|---|---|
| `911twpc` | `m911TWPCBackground` | |
| `jp` | `JPTWDBackground` | 一份程式碼，JPTWD／JPCN／JPMYR 三站共用 |
| `magic` | `MagicBackground` | |
| `mk` | `MKBackground` | 整併基準部署本身 |
| `mk_commercial` | `MKCommercialBackground` | |
| `moremoney` | （共用 `ZunlianBackground`） | 錢多多，無獨立 background 專案 |
| `now888` | `Now888Background` | 注意：非 `Now8888` |
| `sanbayi` | `SanBaYiBackground` | |
| `skyverse` | `SkyVerseBackground` | |
| `slotparty` | `SlotPartyBackground` | |
| `star888` | `Star888Background` | 注意：非 `Star8888` |
| `theone` | `TheOneBackground` | |
| `tts88vip` | `Tts88vipBackground` | |
| `zunlian` | `ZunlianBackground` | |

## dataland `origin` 版本 ↔ 站台（回歸檢查用）

同一報表版本被多站共用。修改某報表類時，**必須重跑所有共用站**的動態驗證，避免修一站壞另一站。

| origin 版本 | 實作類 | 共用此版本的站台 |
|---|---|---|
| `origin_v1` | `OriginV1Report` | mk, mk_commercial, moremoney, sanbayi, zunlian |
| `origin_v2` | `OriginV2Report` | 911twpc, skyverse |
| `origin_v4` | `OriginV4Report` | magic, star888, tts88vip |
| `origin_v5` | `OriginV5Report` | now888, slotparty |
| `origin_v6` | `OriginV6Report` | theone |
| `origin_v7` | `OriginV7Report` | jp |

> 其他報表（main／member／by_day…）的版本分派各站不同，需個別查該站 `config/clients/{code}.php` 的 `versions.dataland.{report}`，或用 `scripts/Resolve-Version.ps1` 解出。

## 用法提醒

- 「MK 扮演某站」＝ 跑 probe 時設 `PROJECT_CODE={code}`（見 `workflow.md`）。
- 版本代號 ≠ 方法名。同一版本類在不同報表下解到不同方法（如 `origin_v2` 在 `origin` 解到 `getCagentcheckList`，在 `origin_member` 解到 `getMemberCheckList`）。以 `DataLandReportResolver::REGISTRY` 為準。

---
**最後更新**: 2026-08-26
**維護者**: 開發團隊
**文件版本**: v1.0
**變更記錄**（里程碑，最多 5 條）:
- v1.0 (2026-08-26): 初版，逐項查證站台↔專案↔origin 版本對照，含版本共用關係
