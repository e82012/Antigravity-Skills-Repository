# 如何撰寫動態驗證探針（繞過 auth，比最終輸出）

> 教「使用 SKILL 的 AI」在**目標專案的 `tmp/{任務名}/`** 下，現建動態探針。骨架為範本，依端點調整。先讀 `rigor-and-antipatterns.md`。

## 前置硬閘門：先確認兩邊連同一個 DB（不過就不准跑）

**跑任何 probe 之前，先比對兩個專案的 `.env` DB 設定是否指向同一個資料庫。** 兩邊連不同 DB，讀到的資料就不同，輸出一定不一樣，測出來完全沒意義——這是動態驗證最常見的假差異來源。

必須逐項相同的鍵：`DB_CONNECTION`、`DB_HOST`、`DB_PORT`、`DB_DATABASE`、`DB_USERNAME`（連同一個庫、同一份資料）。

```bash
# 只擷取 DB 連線識別鍵做比對，不要外洩密碼（DB_PASSWORD 不印、不入報告，呼應全域 §4 資料隱私）
for p in <MK-worktree> d:/wsky/m911TWPCBackground; do
  echo "== $p =="
  grep -E '^(DB_CONNECTION|DB_HOST|DB_PORT|DB_DATABASE|DB_USERNAME)=' "$p/.env"
done
```

判定與處置：
- 五個鍵**逐項相同** → 通過，可往下跑 probe。
- 任一不同 → **停**。先讓兩邊指向同一個 seeded 測試庫（見文末 fixture 對齊），或改用純邏輯驗證(c)。**不得**在 DB 不一致的情況下跑，也不得把因此產生的 mismatch 當成整併差異。
- 注意 `PROJECT_CODE` 未設時會回退用 `DB_DATABASE`（去 `_test` 尾）推站台——若兩邊共用同一個 DB，MK 側**務必顯式設 `PROJECT_CODE`**，否則會被 DB 名帶偏扮錯站。

## 探針要做到的六件事

1. 在**目標專案內** boot Laravel（吃該專案自己的 vendor／config／DB 連線）。
2. 設 `PROJECT_CODE`（僅 MK 側需要，讓它扮演目標站；原專案不設）。
3. 建 `Request`，帶**與對側完全相同**的查詢參數。
4. **繞過 HTTP／middleware／Sanctum**：不經 router，直接呼叫目標 controller method；需登入者時手動注入 user resolver。
5. 取得最終輸出（controller 回應解包），**正規化**後 dump 成 JSON。
6. **保證唯讀**：整段包在 DB transaction 裡最後 rollback，確保驗證不寫髒資料。

## 關鍵陷阱

- **config 快取**：`config/project.php` 用 `env('PROJECT_CODE')`。若專案跑過 `php artisan config:cache`，`env()` 在執行期回 null，`PROJECT_CODE` 會失效。探針啟動前先確認 `bootstrap/cache/config.php` 不存在，或先 `php artisan config:clear`。
- **設 env 的時機**：必須在 `require bootstrap/app.php` **之前** `putenv()` ＋ 寫 `$_ENV`／`$_SERVER`，否則 config 已載入就吃不到。
- **method 的依賴注入**：原專案的方法簽名可能注入 service（如 `originCagentcheckList(Request $r, DataLandServices $s)`）。用 `app()->call([$controller, $method], ['request' => $request])` 讓容器自動補依賴，不要手動 `new`。
- **取輸出的層級要兩邊一致**：兩邊都取「controller 回應解包後的 `data`」，或都取「報表類方法的原始回傳」，**不可一邊取 controller 層、一邊取 service 層**，否則包裝差異會被誤判成邏輯差異。
- **測試 DB**：探針連的應是 seeded 測試 DB，不是正式庫。
- **登入實體不是 `App\Models\User`**：先確認 `$request->user()` 實際回哪個 model——找帶 `HasApiTokens` 的那個（本專案是 `Cagent`，PK=uid；`users` 表是空殼）。用錯 model，`$loginUser->type/cagent_path/uid` 全會 null 而炸。設完 request resolver 還要對實際 guard（`sanctum`）`setUser`，因為程式常走全域 `auth()->user()`。
- **輸入要餵到真實計算路徑**：報表常有短路殼——日期超出限制（本專案 `getValidDateRange` 限近 2 個月）、`exchange_code` 查無→回 404、缺 `cagent_uid`→空結果。亂餵只會兩邊一起走短路，驗不到真邏輯。動探針前先跑一支唯讀 discovery，撈出「有效的登入者（對的 scope）＋ 落在限制內、確定有資料的參數」，見下節。

## 前置：唯讀 discovery 撈有效輸入

寫比對探針前，先在目標專案 tmp 下跑一支唯讀 discovery（只 SELECT），確定：
- **真正的登入 model 與一個有正確 scope 的帳號**（如 admin 型別的 Cagent，能看全部）。
- **落在限制內、確定有資料的參數**（日期區間、幣別、要查的 cagent_uid 等）。
- 若使用者已直接給定驗證參數（日期、幣別、cagent 清單），discovery 只需驗證這些值存在即可。

小陷阱：撈欄位若遇 `Column not found`，先用 `Schema::getColumnListing('表名')` 內省真實欄位再查——別假設 PK 是 `id`（本專案 cagent PK 是 `uid`）。

## 骨架範本（PHP，放 `tmp/{任務名}/probe.php`）

> 效率：一支端點對多組輸入時，**boot 一次、內部迴圈**跑完所有組合再一次寫出，不要每組 boot 一次（boot 一次約 1～3 秒，跑幾十組會很慢）。下方骨架示範單組；多組時把 (3)～(7) 包進 `foreach`。

```php
<?php
// ── 範本：依端點調整 URI、參數、目標 Controller@method、取值層級 ──

// (1) boot 前設站台（僅 MK 側需要；原專案刪這三行）
$code = getenv('PROBE_CODE') ?: 'CHANGEME_code';   // 如 911twpc
putenv("PROJECT_CODE={$code}");
$_ENV['PROJECT_CODE'] = $_SERVER['PROJECT_CODE'] = $code;

require __DIR__ . '/../../vendor/autoload.php';           // 路徑依 tmp 深度調整
$app = require __DIR__ . '/../../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

// (2) 唯讀保證：整段包在交易裡，最後 rollback
DB::beginTransaction();
try {
    // (3) 相同輸入（兩邊共用同一組參數）
    $params  = ['s_date' => '2025-01-01', 'e_date' => '2025-01-07' /* , ... */];
    $uri     = 'dataland/origin';
    $request = Request::create('/' . $uri, 'GET', $params);

    // (4) 繞過 auth：注入登入者（不經 Sanctum）
    //     ★ 登入實體不一定是 App\Models\User！先找出真正的 authenticatable
    //       （帶 HasApiTokens 的那個 model）。本專案後台報表登入者是 Cagent（PK=uid），
    //       users 表反而是空殼。用錯 model 會讓 $loginUser->type 之類全炸。
    $loginUser = App\Models\Cagent::find($loginUid);    // 依專案調整 model 與 uid
    // ★ 只設 request resolver 不夠：程式常走全域 auth()->user()，
    //   必須對路由實際用的 guard（這裡 sanctum）也 setUser。
    $request->setUserResolver(fn ($guard = null) => $loginUser);
    foreach (['sanctum', config('auth.defaults.guard'), 'web'] as $g) {
        if ($g) { try { app('auth')->guard($g)->setUser($loginUser); } catch (\Throwable $e) {} }
    }
    app()->instance('request', $request);               // 讓 request() 也拿到同一個

    // (5) 呼叫目標 controller@method（名稱由 route:list 解出，兩邊可能不同）
    $controllerClass = App\Http\Controllers\DataLandController::class;
    $method          = getenv('PROBE_METHOD') ?: 'CHANGEME_method'; // MK: origin / m911: originCagentcheckList
    $controller      = app($controllerClass);
    $response        = app()->call([$controller, $method], ['request' => $request]);

    // (6) 解包成陣列——兩邊取同一層
    if ($response instanceof Symfony\Component\HttpFoundation\JsonResponse) {
        $payload = $response->getData(true);            // 含 success/message/data
        $data    = $payload['data'] ?? $payload;        // 兩邊統一取 data
    } elseif ($response instanceof Symfony\Component\HttpFoundation\Response) {
        $data = json_decode($response->getContent(), true);
    } else {
        $data = $response;                              // 直接回陣列的情況
    }

    // (7) 正規化（兩邊必須套完全相同的規則，見下）
    $normalized = normalize($data);
    file_put_contents(
        __DIR__ . '/output.json',
        json_encode($normalized, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES)
    );
    echo "OK\n";
} finally {
    DB::rollBack();                                     // 保證唯讀
}

// ── 正規化：排序 key、固定浮點、遮罩易變欄位。兩邊共用這一份 ──
function normalize($v) {
    if (is_array($v)) {
        $isAssoc = array_keys($v) !== range(0, count($v) - 1);
        $out = [];
        foreach ($v as $k => $item) {
            if (in_array($k, ['created_at', 'updated_at', 'id', 'request_id'], true)) {
                $out[$k] = '__MASKED__';                // 遮罩清單要寫進報告
                continue;
            }
            $out[$k] = normalize($item);
        }
        if ($isAssoc) ksort($out);                      // 物件排序 key
        return $out;
    }
    if (is_float($v))  return round($v, 6);             // 浮點固定精度（依業務調整）
    if (is_numeric($v) && !is_string($v)) return $v + 0;
    return $v;
}
```

執行：

```bash
# MK 側（扮演 911twpc）
PROBE_CODE=911twpc PROBE_METHOD=origin php tmp/{任務名}/probe.php   # → tmp/{任務名}/output.json（改名 mk_output.json）
# 原專案側
PROBE_METHOD=originCagentcheckList php tmp/{任務名}/probe.php        # → m911_output.json
```

## 比對兩份輸出

**逐鍵逐值遞迴深比對，全量、不抽樣**（禁比長度／筆數，見反模式）。可寫小工具或用資料結構化 diff，輸出落到 path 級：

```
data[3].winLose : MK = -1200.500000 / 原版 = -1200.000000   ← 實質差異
data[0].agentName : 一致
（遮罩欄位：id, created_at, updated_at, request_id）
```

## fixture 對齊（同輸入的前提）

輸出要可比，兩邊資料要對齊。擇一：
- (a) 兩專案 `.env` 指向**同一個 seeded 測試 DB**（schema 相容時最省事）。
- (b) 匯出一份真實資料快照，各自匯入自己的測試 DB。
- (c) 純邏輯驗證：stub 掉資料抓取，對報表類餵**相同合成輸入列**，只比運算與組裝。
- 環境無法對齊時，明確標「動態未驗證」，不得用靜態冒充動態通過。

## 多輪輸入

至少跑：正常區間、跨月、無資料、單筆、大量、金額極值。每輪兩邊同參數，各自 diff。

---
**最後更新**: 2026-08-26
**維護者**: 開發團隊
**文件版本**: v1.0
**變更記錄**（里程碑，最多 5 條）:
- v1.0 (2026-08-26): 初版，探針六步、DB 同源前置閘門、實跑驗證出的陷阱（登入實體非 App\Models\User／要對 guard setUser／輸入須餵到真實路徑）、唯讀 discovery 前置、boot 一次內部迴圈、boot+繞 auth+唯讀回滾骨架、正規化與 fixture 對齊策略
