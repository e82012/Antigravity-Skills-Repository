# 整併架構：MKBackground 如何扮演 13 站

> 本檔記錄整併版的運作機制，是比對前必讀的地基。所有陳述均實際讀碼查證，來源標於各段。

## 1. 一套碼扮演多站的機制

MKBackground 是**整併基底**：同一份程式碼，靠設定切換成 13 站中的任一站。

- 當前站台由 `env('PROJECT_CODE')` 決定。
  來源：`config/project.php`
  ```php
  $projectCode = match ($rawCode = env('PROJECT_CODE') ?: preg_replace('/_test$/', '', (string) env('DB_DATABASE'))) {
      'mk_demo', '', null => 'mk',
      default  => $rawCode,
  };
  ```
  未設 `PROJECT_CODE` 時，退而用 `DB_DATABASE`（去掉 `_test` 尾）；再不然預設 `mk`。

- 設定合併：`config/project.php` 的 `$base`（所有可用鍵的單一基準，值多為 `null`）與 `config/clients/{PROJECT_CODE}.php`（該站宣告的值）以 `array_replace_recursive` 深度合併，客戶值覆蓋基準值。

- **關鍵**：功能版本一律由各站 config 明確宣告，沒有基準預設值。未宣告 = 該站不提供該功能，存取時回 404（不是錯誤，是正常狀態）。

## 2. Dataland 報表的策略分派

以 dataland 為例，整併把「各站不同的報表邏輯」抽成策略類，用 Resolver 依 config 分派。

- 分派器：`app/Services/DatalandReports/DataLandReportResolver.php`
- 分派邏輯（來源：該檔 `resolve()`）：
  ```php
  $version = config("project.versions.dataland.{$report}");   // 例如 origin → 'origin_v2'
  if ($version === null) abort(404, ...);                       // 本站未啟用
  return self::REGISTRY[$report][$version];                     // → [OriginV2Report::class, 'getCagentcheckList']
  ```
- 登記簿 `REGISTRY` 把「報表代號 → 版本代號 → [實作類, 方法]」寫死在 Resolver 內，不放 config；config 只回答「這站選哪個版本」。
- 報表策略類在 `app/Services/DatalandReports/`：`OriginV1~V7Report`、`DsV1~V10Report`、`MagicV1~V6Report` 等。**這些就是各原專案邏輯被抽出來的整併版**。

Controller 只是薄殼（來源：`app/Http/Controllers/DataLandController.php`）：
```php
public function origin(Request $request) { return $this->run($request, 'origin'); }
private function run(Request $request, string $report) {
    $this->prepare($request);                          // 補預設日期（本週）
    $data = $this->resolver->run($report, $request);   // 分派到報表類
    return CommonServices::jsonResponse(true, 'Get data List successfully.', $data);
}
```

## 3. 原專案的對照結構

原版獨立專案（如 m911TWPCBackground）**沒有** `DatalandReports` 策略目錄。同樣邏輯散在 Controller ＋ Service：

- 來源：`m911TWPCBackground/app/Http/Controllers/DataLandController.php`
  ```php
  public function originCagentcheckList(Request $request, DataLandServices $dataLandServices) { ... }
  ```
- 邏輯本體在 `app/Services/DataLandServices.php`、`app/Services/DataLandVerMagicServices.php`。

**方法名稱兩邊不同**（MK：`origin`；m911：`originCagentcheckList`），這是為什麼比對只能以路由 URI 為錨點。

## 4. 路由錨點法（比對的唯一正確起點）

同一支端點在兩邊的解析路徑：

```
MK（扮演某站）:
  routes/api.php  Route::get('/origin', [DataLandController::class, 'origin'])
    → DataLandController::origin()
      → resolver->run('origin')
        → config('project.versions.dataland.origin')  // 依站台，如 origin_v2
          → OriginV2Report::getCagentcheckList()
            → Repository / Model / SQL

原版 m911TWPCBackground:
  routes/api.php  Route::get('/origin', [DataLandController::class, 'originCagentcheckList'])
    → DataLandController::originCagentcheckList()
      → DataLandServices::...()
        → Repository / Model / SQL
```

**驗證要對比的是這兩條鏈的「最終輸出」**，不是中間結構。

## 5. 路由名稱（route name）不可當錨點

`routes/api.php` 裡多支路由共用同一個 route name（如 `VIEW_CAGENT_REPORT` 被 `/`、`/date`、`/member`、`/by-day`、`/origin` 等多支共用，那是權限碼不是端點識別）。**只有 `HTTP method + URI path` 組合才唯一識別一支端點。**

---
**最後更新**: 2026-08-26
**維護者**: 開發團隊
**文件版本**: v1.0
**變更記錄**（里程碑，最多 5 條）:
- v1.0 (2026-08-26): 初版，記錄 PROJECT_CODE 扮演機制、Resolver 策略分派、原專案對照結構、路由錨點法
