# 如何撰寫靜態比對工具

> 本檔教「使用 SKILL 的 AI」在**目標專案的 `tmp/{任務名}/`** 下，現建靜態比對所需的小工具。全部是範本骨架，依端點調整。先讀 `rigor-and-antipatterns.md`。

## 工具一：路由解析（URI+METHOD → Controller@method）

**正解：用 Laravel 自己的路由表，不要用 regex 硬拆 `routes/api.php`。**
`routes/api.php` 有巢狀 `Route::prefix()->group()`、middleware 鏈、動態命名，regex 解析極易錯（漏拼前綴、抓錯 method）。框架的 `route:list` 是唯一權威來源：

```bash
# 在目標專案根目錄執行
php artisan route:list --json > tmp/{任務名}/routes.json
```

再從 `routes.json` 篩出目標端點（欄位含 `method`、`uri`、`action`）。範例（PowerShell）：

```powershell
# 範本：找 GET dataland/origin 打到哪個 controller@method
$routes = Get-Content tmp/{任務名}/routes.json -Raw | ConvertFrom-Json
$routes | Where-Object { $_.uri -eq 'dataland/origin' -and $_.method -like '*GET*' } |
    Select-Object method, uri, action
# MK 會顯示 ...DataLandController@origin
# m911 會顯示 ...DataLandController@originCagentcheckList  ← 名稱不同，這就是為何要錨 URI
```

- **兩邊都各跑一次**，得到各自的 `Controller@method`。名稱不同是正常的。
- 若專案無法 `artisan`（依賴缺、環境不通），退而用 grep 定位 `Route::...'/origin'`，但要人工確認外層 `prefix` 與 method，不可只憑一行 regex 下結論。

## 工具二：MK 版本解析（站台 → 報表類@method）

MK 側路由只到薄殼 controller，真正邏輯在被分派的報表類。解法不需寫程式，讀兩處對照即可：

1. 站台選哪個版本：`config/clients/{code}.php` 的 `versions.dataland.{report}`。
   例：`911twpc` 的 `origin` → `origin_v2`。
2. 版本對哪個類與方法：`app/Services/DatalandReports/DataLandReportResolver.php` 的 `REGISTRY[{report}][{version}]`。
   例：`REGISTRY['origin']['origin_v2']` → `[OriginV2Report::class, 'getCagentcheckList']`。

若要工具化，範本（PowerShell，純文字擷取，結論仍需人工對照 REGISTRY 確認）：

```powershell
# 讀某站某報表的版本代號
$code = '911twpc'; $report = 'origin'
$cfg = Get-Content "config/clients/$code.php" -Raw
# 於 versions.dataland 區塊找 '{report}' => '值'
```

> 注意：版本代號 ≠ 方法名。同一版本類在不同報表下解到不同方法。一律以 `REGISTRY` 實際內容為準，不要用版本代號去猜方法名。

## 工具三：呼叫鏈逐層對照（人工為主，工具為輔）

拿到兩邊的起點方法後，順著往下讀到 Repository／Model／SQL，**逐邏輯單元對照**（不是整檔 diff）：

對照表逐列填（放報告）：

| 層 | MK（扮演該站） | 原專案 | 差異與判定 |
|----|---------------|--------|-----------|
| 路由 | `GET dataland/origin` | `GET dataland/origin` | 同（錨點） |
| Controller | `DataLandController@origin` | `DataLandController@originCagentcheckList` | 名稱不同，屬重構 |
| 邏輯本體 | `OriginV2Report::getCagentcheckList` | `DataLandServices::...` | 逐項比下列 |
| 查詢表／join | … | … | … |
| where／group by | … | … | … |
| 運算欄位／公式 | … | … | … |
| 回應 shape | … | … | … |
| 邊界處置 | … | … | … |

**禁用整檔行數 diff 下結論**（見反模式）。整檔 diff 只能當「找出候選差異點」的輔助，每個候選都要落到上表某一列的語意判定。

## 產出

- `tmp/{任務名}/routes.json`（兩邊各一，可加前綴 `mk_`／`m911_`）。
- `tmp/{任務名}/static-report.md`：填好的呼叫鏈對照表 ＋ 各差異的初步分級。

---
**最後更新**: 2026-08-26
**維護者**: 開發團隊
**文件版本**: v1.0
**變更記錄**（里程碑，最多 5 條）:
- v1.0 (2026-08-26): 初版，路由以 artisan route:list 為權威來源、版本解析讀 config+REGISTRY、呼叫鏈逐層語意對照表
