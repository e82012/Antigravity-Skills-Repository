# 瀏覽器操作配方（Browser pane）

驅動工具為 `mcp__Claude_Browser__*`。所有配方以 `browser_batch` 為預設形式。

## 0. 環境探針（每站每次開工必跑）

進站第一件事，把這段丟進 `javascript_tool`，結果記進頁面文件開頭：

```js
const q=s=>[...document.querySelectorAll(s)];
({
  url: location.href,
  viewport: {w: innerWidth, h: innerHeight},
  hidden: document.hidden,
  // 元件前綴：不同站台可能不同，且同站可能混用多個
  prefixes: [...new Set(q('[class]').flatMap(e=>[...e.classList])
    .filter(c=>/-(select|input|btn|modal|picker|table|radio|checkbox|notification)(-|$)/.test(c))
    .map(c=>c.split('-')[0]))],
  rootId: document.querySelector('#root') ? 'root' : (document.querySelector('#app') ? 'app' : null),
  cssInJs: !!document.querySelector('[class*="css-"]')   // antd v5 特徵
})
```

**前綴不得跨站沿用。** 已知 `sndams.ds88.tw` 把多數元件前綴改成 `custom-modal-`，但 Notification
仍是 `ant-`——同一站混用兩種前綴。因此所有選擇器一律寫成 `[class*=select-selector]` 這種
**後綴比對**形式，不要寫 `.ant-select-selector`。

## 1. 操作路徑、viewport 與座標

### 1.1 預設路徑：ref（不需截圖、不需換算）

**進頁面後一次 `read_page` `filter:"all"` 取回整頁 ref，之後所有點擊都用 `ref`。**
ref 由元素解析直接命中目標，不吃截圖座標系、不受縮放與版面位移影響，
也不需要事先截圖——這是回合成本最低的操作路徑（1 回合，座標路線要 3 回合）。

`filter` 一律用 `"all"`。`"interactive"` 會漏掉 combobox 與 checkbox。

ref 什麼時候會失準，以及怎麼補：

| 情況 | ref 狀態 | 處置 |
|---|---|---|
| `navigate` 之後 | 全部重新編號 | 重跑 `read_page` |
| 捲動之後 | 既有 ref 的座標不更新 | 用 `computer scroll_to {ref}` 捲動，或重跑 `read_page` |
| 畫面被縮放（frame ≠ viewport） | ref 與座標同時失準 | 環境問題，見 §1.6／§1.7 |

**ref 真的取不到目標時才降級走座標**（`troubleshooting.md` 降級順序第 2 級）。
實測整輪測試 277 次點擊全走座標路線、`read_page` 一次都沒用，
光這條就多燒 139 張前置截圖與相應回合。

### 1.2 備案：座標換算（走座標路線時最重要的一條）

**`computer` 的 `coordinate` 參數採「截圖座標系」，不是頁面 CSS 座標。** 用
`getBoundingClientRect()` 算出的頁面座標直接丟進去會點錯位置，而且**不會報錯**——它會點在
頁面上另一個元件上。

```js
// frameW / frameH 取自截圖回報的 "coordinate frame: {W}x{H}"
const toFrame = (px, py) => [Math.round(px * frameW / innerWidth),
                             Math.round(py * frameH / innerHeight)];
```

再說一次：`ref` 點擊不需要換算，也不需要先截圖。走到這一節代表 ref 已經取不到目標。

實測（viewport 1440×900、frame 800×492）：`#memId` 中心頁面座標 `(202,420)`，直接點會聚焦到
頁面下方 351px 處的 `#game_rebate_LIVE_copy_form`（`420 × 900/492 ≈ 768`）；換算成 `(112,230)`
後才正確命中。

**用 `resize_window` 模擬視窗時，換算比例會被放大到不可能忽略。** 模擬尺寸只改 `innerWidth`／
`innerHeight`，截圖 frame 仍是 pane 的實際大小。實測模擬 1511×918、frame 800×478 時比例是 0.529——
頁面座標 `(277,372)` 要換成 `(147,194)`，直接丟原值會點到頁面另一處且無任何錯誤。
每次改過模擬尺寸就重取一次 frame，不要沿用上一輪的比例。

### 1.2.1 改過模擬尺寸後要重新載入，元件才會以新寬度掛載

RWD 斷點是在元件掛載時判定的，`resize_window` 只改視窗尺寸不會讓已掛載的元件重算。
實測機台報表頁：pane 1280px 時搜索條件區收成一顆浮動鈕（該鈕帶 `xl:hidden`，Tailwind `xl` 斷點正好
1280px），把模擬尺寸拉到 1511 後**畫面完全沒變**，UI 指紋仍是收合版的 `494dedaf`；`location.reload()`
之後才變成完整版的 `6d8f6d27`，與原站一致。

順序固定為 **`resize_window` → `reload` → 驗 `innerWidth` → 再比對**。
少了中間那步，會把 RWD 收合誤判成「合併站缺少搜索條件區」。

### 1.3 捲動與座標失效

**頁面的捲動容器不是 `window`**（Pro Layout 的內層 content div），`window.scrollTo(0,0)`
無效，`scrollY` 恆為 0。一律用目標元素的 `scrollIntoView({block:'center'})`。

因此**跨視窗的目標不能一次取座標**——捲動後其餘目標就不在可視區了。

**座標在任何狀態改變後即失效**，不只捲動：查詢結果筆數變了、彈窗開關、選了一個 radio、
表單欄位增減，版面都會位移。**同一批次裡做過會改變版面的動作之後，後續目標必須重新取座標。**

實測三次都是同一個坑，且每次都差點被記成功能失效 `[實測]`：

| 場景 | 位移 | 誤判風險 |
|---|---|---|
| 代理登入日誌搜索後結果 30 筆 → 2 筆 | 「清除搜索」y 476 → 519 | 誤判「清除搜索沒反應」 |
| 玩家額度日誌選了操作類型 radio | 「搜索」y 540 → 499 | 誤判「操作類型篩選失效」 |
| 捲動後沿用舊 ref | ref 座標不更新 | 誤判「元素點不到」 |

**判 `FAIL` 前一律重取一次座標並確認 `hit: true`，再點一次。**

### 1.4 同視窗多目標批次（實測省 67% 呼叫）

**同一個功能項目的動作要一批打完，不要逐欄來回。** 走 ref 路線時更沒有理由拆開——
ref 不會因為前一個動作改變版面而失效，整組欄位可以直接串在同一個 `browser_batch` 裡。

以下是走座標路線時的批次寫法。**同時落在可視區內的目標可以一次取完座標，再一批打完。** 實測填 `memId`／`name`／`point`
三個欄位：批次做法 2 次呼叫（取座標 1 次 ＋ 動作與驗證 1 次），逐欄做法 6 次。

```
呼叫 1（JS）：scrollIntoView 第一個目標 → 回傳各目標的 frame 座標，
              並逐一檢查 inView 與命中；有任一項 false 就不要納入這批
呼叫 2（batch）：click → type → click → type → … → wait → JS 一次驗證全部
```

不適用於 Select——下拉浮層的位置要展開後才知道，每個 Select 仍是「開 → 讀 → 選 → 驗」。

`javascript_tool` 只能跑頁面內的 JS，**做不了真實滑鼠點擊**（合成事件屬第 4 級降級）。
所以單一操作的回合數下限就是 2：取座標一次、點擊與驗證一次。這是工具邊界，不是寫法問題。

| 事實 | 說明 |
|---|---|
| pane 尺寸決定版面 | 寬度不足時後台 desktop 版面觸發 RWD，側邊選單變抽屜覆蓋表單。實測 1440×900 正常，412×258 會被抽屜蓋住 |
| 座標點擊需先截圖 | 沒有先 `screenshot`，帶 `coordinate` 的點擊直接報錯（ref 點擊不受此限） |
| `scroll_to` 不更新既有 ref 座標 | 捲動後要重新 `read_page`／`find` 才會拿到新座標 |
| `navigate` 後 ref 會重新編號 | 導覽後所有舊 ref 作廢 |
| 浮層會殘留 | 開著的下拉不會被 `Escape` 或 `body.click()` 關掉，會蓋住後續操作區。卡住時直接 `navigate` 重載頁面 |

### 1.5 異常處理：畫面沒在繪製

> 這一節是**異常處理**。常態做法是開工前就確認 Claude 視窗在前景（見 `SKILL.md` 環境前置條件）；
> 實測靠截圖硬撐一輪要多燒 47 張救援截圖與相應回合，**先把視窗弄對永遠比較便宜**。

**Claude 視窗被其他視窗蓋住時，頁面不會繪製，`innerWidth/innerHeight` 讀出來是 `0×0`。**
此時載入的頁面，RWD 元件會以「極小螢幕」初始化——**整個搜索條件區不渲染，而且視窗回到前景後
也不會自我修正**。

這會製造極具說服力的假象：畫面上真的沒有日期選擇器、沒有快捷鍵、沒有搜索按鈕，
DOM 裡也確實查不到，看起來就是「這頁功能缺漏」。`[實測]`

實測證據：`會員登入日誌` 同一頁、同一 viewport（1042×922）、同一網址，
在未繪製狀態載入 → `searchPanel: false`、`pickers: 0`；
在繪製狀態下重載一次 → `searchPanel: true`、`pickers: 16`、快捷鍵全部出現。

**開工前與每次進頁面後都要檢查：**

```js
({ vw: innerWidth, vh: innerHeight })   // 任一為 0 就停下，畫面沒在繪製
```

`computer{action:"screenshot"}` 回報 `did not finish rendering in time` 是同一個症狀。

**處置順序：**

1. **先請使用者把 Claude 視窗帶到前景、不要被其他視窗蓋住。** 這是根因，
   以下幾步都只是視窗無法置前時的補救。
2. 先截一張圖強制繪製，確認 `innerWidth/innerHeight` 不是 0。
3. **用 `javascript_tool` 執行 `location.reload()` 或 `location.href=...` 換頁**，
   不要用 `navigate` 工具——實測 `navigate` 之後 viewport 會再度變成 `0×0`，
   等於又用錯誤尺寸掛載一次。
4. **重載後立刻連續截圖**，在掛載期間持續強制繪製。這是實測唯一穩定的做法：

   ```
   browser_batch:
     javascript_tool  location.reload()
     computer         screenshot (scale 0.1)
     computer         screenshot (scale 0.1)
     computer         wait 2
     computer         screenshot (scale 0.1)
     computer         wait 3
     javascript_tool  驗證 searchPanel 是否出現
   ```

   只重載不截圖時，掛載瞬間常落在不繪製的空檔，面板依然不會出現。

5. **`resize_window` 救不回來**：實測元件只在掛載時量測一次，事後改變 viewport
   不會觸發重新量測。
6. 重載後確認搜索條件區存在，再開始測。
7. 視窗已置前仍反覆繪製失敗時，依 §8 標 `BLOCKED`。

**未經這道檢查，不得把「某個區塊不存在」記為功能缺漏。**

### 1.6 穩定組態（先把環境弄對，再談點擊）

**關掉 viewport 模擬 ＋ 讓 Browser pane 本身夠寬**，這是唯一實測穩定的組態
（1042×922 實測順暢）。`resize_window` 的放大模擬會讓 ref 與座標點擊雙雙失準，
**不要拿它當 pane 太窄的替代方案**。

pane 寬度不足時後台會觸發 RWD：側邊選單變抽屜覆蓋表單，更嚴重的是**整個搜索條件區不渲染**
（實測 682px 時棄分記錄頁全頁只剩 1 個 input）。這是環境問題，依 §8 標 `BLOCKED`
並請使用者拉寬 pane。

### 1.7 開工前必做：確認座標系是 1:1

```
截圖回報的 "coordinate frame: {W}x{H}"  必須等於  JS 讀到的 innerWidth / innerHeight
```

**不相等就代表畫面被縮放（letterbox），此時 ref 與座標點擊都會落在錯誤位置，而且不會報錯**
`[實測]`——工具照樣回報「已點擊」，頁面毫無反應。

frame 與 viewport 等比但不相等時（模擬關閉、pane 原生渲染後縮圖），
`frameX = pageX * frameW / innerWidth` 可用，**但每次開工要用一次探針驗證**：
挑一個文字輸入框，換算後點擊並確認 `document.activeElement` 就是它。驗過再開始測。

`resize_window` 模擬造成的不相等同樣用 `frameW / innerWidth` 換算即可。實測模擬 1511×918、
frame 800×478（比例 0.529）時，換算後的 radio、submit 按鈕與返回連結皆一次命中。
照上一段的做法先用輸入框驗一次比例，驗過就能整輪沿用。

pane 太窄時後台會觸發 RWD、側邊選單變成抽屜覆蓋整個表單（實測 538×922 即如此），
這時無論怎麼點都會打在遮罩上——**這是環境問題，依 §8 標 `BLOCKED` 並請使用者拉寬 pane，
不要用模擬硬撐。**

### 1.8 一輪測試最容易燒掉時間的四件事

實測四個頁面花掉兩小時，逐項盤點後的四個成因，每一項都不是工具限制：

| # | 做錯的事 | 該怎麼做 |
|---|---|---|
| 1 | 合併站跑完一輪、原站再跑一輪 | **兩站壓進同一個 `browser_batch`**。同一個動作對兩站各放一個 action，一次呼叫拿回兩邊結果，當場判定 |
| 2 | 幾乎每次點擊前都重測座標 | 兩站版面相同時**座標也相同**——量一次兩站共用。實測整輪的 radio、submit、返回鍵座標在兩站逐項相等 |
| 3 | 用 `location.reload()` 清殘留浮層 | 重載一次約 10 秒，實測燒掉 25 次。**開浮層時就把關閉鈕座標一起取回來**，關閉鈕點不到才考慮重載 |
| 4 | 看到「修改」「轉移」就當成 modal 去找彈窗 | **先探結構再決定操作路徑**：`document.querySelectorAll('[class*=modal-content]')` 為空就是頁內 inline 編輯。實測「修改」與「轉移代理商」都是 inline，當成 modal 找了半天 |

判準很簡單：**每多一次呼叫，都要答得出它帶來什麼新資訊。** 答不出來的就是第 2、3 類。

### 1.9 下拉浮層在關閉動畫期間 `pointer-events: none`

antd 的下拉關閉時浮層還留在 DOM 裡、選項讀得到，但整層 `pointer-events` 已被設成 `none`——
這時候點擊會穿透到後面的頁面，**工具照樣回報「已點擊」，選取值完全沒變**。

點浮層裡的選項前先驗一次：

```js
const d = document.querySelector('[class*=select-dropdown]:not([class*=hidden])');
getComputedStyle(d).pointerEvents === 'auto'   // false 就等動畫結束再點
```

「選項看得到卻選不動」先查這一條，不要急著判元件壞掉或改走 JS 降級。

### 1.10 點不到時的第一個檢查是 `elementFromPoint`，不是座標

「按了沒反應」有兩種完全不同的成因，混在一起會一路試錯：

```js
const b = /* 目標元素 */;
const r = b.getBoundingClientRect();
const top = document.elementFromPoint(r.x + r.width/2, r.y + r.height/2);
({ hit: b.contains(top) || top === b, top: top && top.className, disabled: b.disabled })
```

- `hit: false` → 有東西蓋著。實測最常見的是**關掉的彈窗留下 `modal-wrap` 遮罩**——
  按 Escape 不一定關得掉，重新 `navigate` 一次最快。
- `hit: true` 但點了沒反應 → 座標換算或 frame 高度的問題，往下一條。
- `disabled: true` → 元件本來就停用，兩站一起確認後直接判定，不要繼續試。

### 1.11 frame 高度會在 478／486 之間跳動，每次座標點擊前重取一次

同一個 tab、同一個模擬尺寸，`screenshot` 回報的 coordinate frame 會在 `800×478` 與 `800×486`
之間變動（pane 高度隨 UI 元素增減）。用舊的 478 去換算 486 的畫面，偏移約 1.7%——
在畫面上半部無感，**到了 y≈450 的送出按鈕就剛好落在按鈕下緣外面**。

實測代價：同一顆「提 交」連點四次沒反應，一度誤判成前端壞掉。

做法是**每次要用座標點擊前，先跑一次 `screenshot` 並用它回報的 frame 高度換算**，
不要把換算比例快取跨回合重用。`ref` 路線不受影響，這也是 §1.1 把 ref 列為預設路徑的理由之一。

## 2. 雙站比對的 tab 管理

```
tabs_create → tabId A：原站
tabs_create → tabId B：合併站
```

- 兩站不同網域時登入態互不干擾，**同一個 tab 跑完整站，不要每頁重開**。
- 每次呼叫明確帶 `tabId`，不要依賴「目前 fronted 的那個」。
- 密碼由使用者自行輸入。**AI 不得將密碼打進登入欄位**，這條沒有例外。

## 3. 進頁面 ＋ 掛監聽 ＋ 盤點（階段 A）

計畫書 §1.4 要求三個監聽器在進入頁面**之前**掛上。Browser pane 的
`read_network_requests` / `read_console_messages` 是事後查詢環形緩衝，因此順序改為：
**先 navigate，再立刻查詢**，中間不做任何其他操作。

```
browser_batch:
  1. navigate {url}
  2. computer wait 2
  3. read_network_requests {limit: 80}
  4. read_console_messages {onlyErrors: true}
  5. javascript_tool  ← 盤點探針（見 component-playbook.md §0）
  6. read_page {filter: "all"}  ← 一次取回整頁 ref，當本頁的操作索引用到 navigate 為止
```

第 6 步是整輪測試最省回合的一步：ref 拿到手之後，本頁所有點擊都不必再截圖、不必再算座標。

## 4. 操作 ＋ 驗證（階段 B）

**點擊與驗證必須分開兩次呼叫**，React 18 批次更新會讓同批次的讀取拿到舊值。
這是工具邊界造成的回合下限，也是**一個功能項目的回合預算上限（3 回合）** 的由來。

走 ref 路線（預設，2 回合）：

```
呼叫 1（batch）：computer{ref} 點擊 → type → computer{ref} 點擊 → type → … → wait
呼叫 2（batch）：javascript_tool 一次驗證全部狀態 → read_network_requests 取本次 API
```

走座標路線（ref 取不到時的備案，3 回合）：

```
呼叫 1（JS）  ：scrollIntoView → 回傳各目標的 frame 座標並檢查 inView
呼叫 2（batch）：screenshot → 點擊 → type → … → wait
呼叫 3（batch）：javascript_tool 驗證狀態 → read_network_requests
```

**同一個功能項目的所有欄位要串在同一批裡**，不要一欄一次呼叫——
實測平均每批只塞 5.3 個動作，逐欄操作是回合數膨脹的主因之一。

驗證要讀出**具體的狀態變化**（`aria-expanded`、選中值、清單筆數、URL），
不接受「工具回報已點擊」當作通過。

## 5. API 攔截落檔

`read_network_requests` 取清單，`requestId` 取單筆 body。落檔格式依
`evidence-format.md`，路徑為 `doc/e2e/{站台}/{頁面代號}/{情境}_{站別}_api.json`。

比對時忽略計畫書 §5.4 的允許差異欄位（時間戳、主鍵、UID、token、分頁游標）。

## 6. 截圖時機

只在這四種情況截圖，其餘一律用 DOM 探針：

1. 計畫書 §5.3 的 UI 比對出現差異，需兩站並列為證。
2. 不可逆操作前後各一張。
3. 版面錯亂、白畫面等「必須看見才說得清」的異常。
4. 頁面文件需要一張代表圖。

截圖用 `scale` 壓到 0.4 以下即可辨識版面；要看細節用 `zoom` 框特定區域，不要整頁全解析度。

## 7. 雙站比對（階段 C）

UI 逐項重放比對又慢又容易被渲染時序干擾。**比 API 就直接打 API**，UI 另外用文字指紋比一次即可。

### 7.1 取得可直接呼叫 API 的憑證

先確認 token 放哪、怎麼送。實測 ds88／sndams 兩站皆為：cookie `token` 只是儲存，實際驗證走
`Authorization: Bearer`。用 `fetch` 帶 cookie 會回 401，容易誤判成「登入失效」。

```js
window.__auth = () => ({Accept:'application/json',
  Authorization: 'Bearer ' + decodeURIComponent(
    document.cookie.split(';').map(s=>s.trim()).find(s=>s.startsWith('token='))?.slice(6))});
```

header 名稱不要用猜的，開工時實測一輪（`Bearer x` / 裸 token / 自訂 header 各打一次看狀態碼）。

### 7.2 正規化 ＋ hash 比對

兩個 tab 是不同 origin，拿不到彼此的資料，所以**各自算 hash、只比 hash**，一致就結案、不一致才鑽下去。

```js
window.__canon = v => v===null||typeof v!=='object' ? JSON.stringify(v)
  : Array.isArray(v) ? '['+v.map(__canon).join(',')+']'
  : '{'+Object.keys(v).sort().map(k=>JSON.stringify(k)+':'+__canon(v[k])).join(',')+'}';
window.__h = s => {let h=2166136261;for(let i=0;i<s.length;i++){h^=s.charCodeAt(i);h=Math.imul(h,16777619)}
  return (h>>>0).toString(16)};
```

鍵要遞迴排序，否則兩站的鍵序差異會製造假陽性。一次丟一整批路徑進去跑，回傳
`{path, status, message, listLen, hash}`，一輪就掃完一頁的所有端點。

hash 不同時，把可疑欄位挑掉再算一次來定位差異來源。實測 `getCagentChildList` 唯一的差異就是
`path` 與 `next_page_url` 帶各自網域——這屬計畫書 §5.4 允許差異，剔除後 hash 全等。

### 7.3 兩層一起做：逐功能交錯，不要分兩輪

第一層（合併站功能）與第二層（原站比對）**同一輪做完**：

```
合併站操作功能 A → 攔到實際送出的請求 → 原站做同一個操作 → 比請求＋回應 → 判定 A
合併站操作功能 B → ...
```

不要「合併站全部跑完，再兩站各跑一次」——同一個功能會被操作三遍，而且比對用的參數要另外設計，
容易和當初實測的條件對不起來。

交錯的關鍵是**比對參數直接來自合併站的真實操作**：用 §7.6 的 XHR 觀察器攔下 URL，
原封不動拿去原站重放，兩站條件天然一致。

比請求本身也有價值：兩站送出的 query string 逐字相同，就等於證明了前端組條件的邏輯一致
（實測用這招確認了兩站的時間區間都以中午 12:00 為界）。

### 7.3.1 開了 `APP_DEBUG` 的錯誤回應，差異多半在部署層

兩站的 500／405 回應會夾帶完整堆疊軌跡，hash 幾乎一定不同，但差異通常不是行為：

| 差異來源 | 是否算不一致 |
|---|---|
| 部署路徑（`MKBackground.merge` 對 `.snd`） | 否 |
| SQL 錯誤字串裡的 `created_at` 時間戳 | 否（計畫書 §5.4） |
| 自家原始檔的**行號**（重構後同檔差一行） | 否 |
| 例外類別、訊息、拋出的檔名、堆疊層數 | **是** |

先把部署路徑正規化再比；若還不相等，**切段找出差在哪**而不是直接判不一致：

```js
const n = JSON.stringify(body).replace(/MKBackground\.(merge|snd)/g, 'MKB');
const chunks = []; for (let i = 0; i < n.length; i += 1000) chunks.push(__h(n.slice(i, i + 1000)));
```

兩站的 chunk 陣列一比就知道差在第幾段，取那 1000 字出來看即可。
實測靠這招把一次「hash 不同」收斂成「`VerifyStatus.php` 行號 29 對 28」，判定為一致。

### 7.4 寫入端點：兩站各做一次，成對還原

共用資料庫時，一站寫入另一站看得到。做法是**兩站各建立自己的一筆**（`cmpo0909` / `cmpm0909`），
比回應，再比兩筆資料逐欄的差集（排除 uid、token、帳號、時間、path）。差集為空才算一致。

點數這種可逆操作用**對稱操作**還原：原站 +100、合併站 +100、原站 −100、合併站 −100，
最後回讀確認餘額與起始值相同，並把還原結果寫進證據檔。

**兩站的寫入一定要序列執行，而且每站用不重複的值。** 共用資料庫時平行送出會互相污染：
實測兩站同時建立 `content: x`，先到的建立成功、後到的撞上「已存在」回 422，
看起來就像站別差異——那一輪結果只能作廢重跑。

還原前先想清楚刪除順序：測試資料可能被分到回應的新群組鍵底下
（實測寫入一個未定義的 `type` 後，清單回應多出一個以該值為鍵的群組，
用固定的鍵去找會漏掉，要用 `Object.values(data).flat()` 掃）。

錯誤路徑跟成功路徑一樣要比：超額、負值、零值、不存在的 id、重複的唯一鍵。
重構最容易掉的就是這些分支，且它們大多不會寫資料，成本很低。

**payload 從後端原始碼取，不要用猜的**——`grep` 出 controller／service 實際 `$request->get()` 的鍵。
猜錯會得到一個假的「兩站都失敗」結論。

### 7.4.0 基準要落在對話裡，不要只存在 `window`

還原驗證的前提是手上有測試前的完整 payload。存進 `window.__snapshot` 看似方便，
但**任何一次頁面重載都會把它清掉**——而寫入測試幾乎必然伴隨重載。

實測踩過：權限資料寫入前把基準存在 `window`，還原後想逐位元組比對時基準已消失，
只能退而證明「81 項狀態全部還原」，整體 hash 為何仍有差異則查不出來，只能據實標為未查清。

**基準要嘴巴講出來**：把 hash 與關鍵欄位直接寫進回覆或證據檔，
payload 大就落成檔案。判斷準則是「頁面重載後這份基準還在嗎」。

### 7.4.04 高風險頁先探「有沒有寫入端點」

面對維護模式、全站設定、權限這類頁面，先別急著評估「要不要冒險寫」——
**直接對該資源送一次 `POST` 與 `PUT`，看它支不支援**：

```js
await __post('/api/admin/config', {});          // 405 → 根本不能寫
await __post('/api/admin/config', {}, 'PUT');   // 405
```

實測：系統設置頁看起來全是高風險開關（維護中、開放註冊、預設密碼），
一探才發現 `/api/admin/config` 只支援 `GET`／`HEAD`，畫面也沒有提交鈕——
整頁唯讀，寫入測試的風險評估根本不必做。

這是成本最低的判斷：一次請求就把「要不要冒險」變成「有沒有得冒險」。
真的支援寫入時，再走 §7.4.05 的三個前置。

### 7.4.05 動權限、設定這類資料前的三個前置

共用資料庫下改設定比改業務資料更難收拾，動手前先確定：

1. **選不會升權的項目。** 挑檢視類、且原本為關閉的項目，開→關一輪即回原狀；
   避開授予退款、轉移代理這類操作權限，也避開自己登入帳號所屬的那個權限標籤。
2. **兩站操作不同的目標。** 同一筆設定兩站輪流寫，會重演 §7.4.2 的先後手問題。
3. **同時留一個「未動過的對照組」。** 另取一筆同型資料記下基準，
   還原後回讀它——沒變就證明寫入沒有外溢，變了就知道影響範圍比預期大。

### 7.4.1 寫入後，另一站的表格是舊快照

共用資料庫時兩站看的是同一份資料，但**畫面不會互相通知**。
A 站建立或刪除之後，B 站沒有重新查詢，表格仍停在上一次的結果
（實測出現過「清單 API 回 15 筆、DOM 卻有 17 列」）。

拿 DOM 當比對證據之前**兩站都要重新載入**；只比 API 回應則不受影響。

### 7.4.2 改同一筆資料時，兩站要交錯換手

共用資料庫下，「更新」類端點常以**異動筆數**判定成敗——改到值回成功，值沒變回失敗。
兩站對同一筆送出相同 payload 時，先送的那站改成功、後送的那站因為值已相同而回失敗，
看起來就像站別差異。

實測踩過：把兩站的 `PUT` 放進同一個 batch 依序送出，
合併站回 `update promo code successfully.`、原站回 `update promo code failed.`，
差點記成不一致。正確的驗證方式是**交錯換手**，讓兩站各自扮演一次「先手」與「後手」：

```
原站送新值    → successfully
合併站送同值  → failed
合併站送新值  → successfully
原站送同值    → failed
```

四步的回應兩兩對稱，才證明差異來自送出的值、不是站別。**每一步單獨送出並回讀**，
不要壓進同一個 batch，否則分不清是誰先到。

收尾記得把值改回原狀，並用清單 hash 確認回到測試前。

### 7.4.3 直接打 API 還原時，payload 一定要帶完整欄位

Laravel 的 update 控制器常對未帶到的欄位套預設值，**送半套 payload 等於把沒帶的欄位歸零**。

實測：為了還原一個 `game_highlight`，送了 `PUT /api/gameList/444 {"popularity_ranking":208}`，
回 200「update successfully」，結果 `game_highlight`、`game_type_uid`、`game_subtype_uid`
三個欄位一起被清成 0——原本的 SLOT／Slots 分類消失。

還原流程固定三步：

```
1. GET 清單或詳情，取回整列
2. 以整列為底，只覆蓋要改的欄位（刪掉 platform / created_at / updated_at / deleted_at 這類唯讀欄）
3. PUT 整包，再 GET 回來逐欄核對
```

**能走畫面就走畫面**——UI 的送出天生帶完整表單，比手組 payload 安全。
直接打 API 只用在畫面路徑本身壞掉、或畫面被遮罩擋住的時候。

被歸零的欄位要怎麼救：同類資料的兄弟列通常共用同一組值（例：同平台的 GRslot 遊戲
`game_type_uid` 全是 2、`game_subtype_uid` 全是 16），撈一列兄弟來比就能還原。

### 7.5 介面層：文字指紋

```js
const S=new Set();
document.querySelectorAll('label,button,th,[placeholder],.ant-tabs-tab').forEach(e=>{
  const t=(e.innerText||'').trim().replace(/\s+/g,' ');
  if(t&&t.length<40)S.add(t);
  const p=e.getAttribute('placeholder'); if(p)S.add('ph:'+p)});
```

排序後取 hash。要先排掉**使用者自己的資料**（瀏覽器端保存的捷徑、個人化欄位設定），
否則會把自己測試時留下的痕跡當成站別差異。

指紋只證明「可見文字集合相同」，收合中的面板不在裡面——面板沒展開就別把該面板的項目標成已比對。

### 7.6 判斷「按鈕有沒有真的發請求」要掛 XHR，不要看 network 面板

`read_network_requests` 會漏抓——實測有請求送出卻沒出現在清單裡，差點把「有重查」誤判成「沒重查」。

掛 `XMLHttpRequest.open` 觀察：

```js
if(!window.__xhrHooked){window.__xhrHooked=1;window.__xlog=[];
  const o=XMLHttpRequest.prototype.open;
  XMLHttpRequest.prototype.open=function(m,u,...r){
    if(String(u).includes('/api/'))window.__xlog.push(m+' '+u);
    return o.call(this,m,u,...r)};}
```

**先確認前端走哪一種**：這些後台用 axios，走 XHR，掛 `window.fetch` 一筆都攔不到
（而自己用 `fetch` 打的探針又照樣有效，很容易誤以為 hook 壞了）。

觀察器只是旁聽，不偽造操作，UI 判定仍然有效。點擊前清空 `__xlog`，點完等 2 秒再讀。

### 7.7 虛擬滾動的下拉選單，用 `scrollHeight` 數項數

antd 的 Select 只渲染可視範圍那 11 筆，`querySelectorAll('[aria-selected]')` 數出來永遠是 11。
用 JS 設 `scrollTop` 也不會觸發重新渲染。

改量容器高度：

```js
const h=document.querySelector('.rc-virtual-list-holder');
Math.round(h.scrollHeight / 32)   // 32 = 單列高度，先量一列確認
```

實測用這招比出原站 127 項、合併站 134 項，證實 API 的筆數差異確實傳到畫面。

### 7.8 換頁會清掉 `window` 上的 helper

（另見：首次進站的請求本來就攔不到——觀察器是載入後才注入的。
補救方式是 `performance.getEntriesByType('resource')`，
它記得載入期間打過的所有 URL：

```js
performance.getEntriesByType('resource').map(e => e.name)
  .filter(u => u.includes('/api/')).map(u => u.replace(/^https?:\/\/[^/]+/, ''))
```

用來找出「這個頁面進來時到底打了哪支端點」比重載一次再攔更省事。）


`location.href=...` 之後注入的函式全沒了，而且在同一次 `javascript_tool` 呼叫裡換頁會直接報
`Inspected target navigated`。換頁與取值要拆成兩次呼叫，helper 每頁重新注入。

### 7.9 差異出來之後，先判「前端還是後端」再寫問題單

比對出 `false` 只完成一半。**同一個畫面差異，根因在前端或後端，處置對象與嚴重度完全不同**——
沒判就寫問題單，等於把分工丟給讀者猜。

三種探法，由快到慢：

**① 對合併站送原站那條路徑／那組參數。** 通得過就是前端問題。

```
原站  PUT /api/gameList/444        → 200
合併站 PUT /api/game-items/444      → 405   ← 前端打的
合併站 PUT /api/gameList/444        → 200   ← 後端其實是通的
```

實測用這招把「功能壞掉」收斂成「前端一行路徑寫錯」，後端完全不用動。

**② 缺欄位就試著把那個欄位寫進去。** 寫得進去＝後端有、前端沒渲染。

```js
p.new_game_highlight = 5;              // 合併站畫面上根本沒這欄
await __api('/api/gameList/444', {method:'PUT', body:JSON.stringify(p)})  // 200
```

寫不進去才往後端查（`grep` Request 驗證規則與 Service 有沒有真的讀那個欄位，見公版 §1.3 三步查證）。

**③ 參數差異就把兩種寫法在兩站各打一次（2×2）。** 四個回應 hash 全等＝後端一致，差異只在前端組參數。

```
原站區間 → 原站 / 合併站
合併站區間 → 原站 / 合併站      四格 hash 相同就結案
```

**分不出「端點不存在」與「端點唯讀」時看 Content-Type。** Laravel 回 405 並列出
`Supported methods: GET, HEAD`，很容易誤讀成「後端只開放唯讀」；但 SPA 的 catch-all
也會吃掉 GET，所以那行講的可能是 fallback 而不是真路由。GET 一次看回的是 JSON 還是 `text/html`：

```js
const r = await fetch(u, {headers:{Authorization:'Bearer '+__tk}});
r.headers.get('content-type')   // text/html → 這條路由根本不存在
```

**結論寫進 README 的「差異的根因歸屬」表**（見 `evidence-format.md` §2.5），
每列都要寫「打了什麼、回了什麼」，不要只寫「前端問題」。

---
**最後更新**: 2026-09-11
**維護者**: 開發團隊
**文件版本**: v7.0
**變更記錄**（里程碑，最多 5 條）:
- v7.0 (2026-09-11): 新增 §7.9 差異出來之後先判前端或後端——三種探法（送原站路徑、試寫缺漏欄位、參數 2×2 交叉），
  並補上以 Content-Type 分辨「端點不存在」與「端點唯讀」
- v6.0 (2026-09-11): 新增 §1.10 點不到時先查 `elementFromPoint`（殘留 `modal-wrap` 遮罩是最常見成因）、
  §1.11 frame 高度在 478／486 間跳動必須每次重取、§7.4.3 直接打 API 還原要帶完整 payload
  （實測半套 payload 讓三個欄位一起歸零）
- 訂正 (2026-09-11): §1.7 「模擬開啟造成的不相等無法換算補救」更正為「同樣以 `frameW / innerWidth` 換算即可」——
  實測模擬 1511×918、frame 800×478 換算後逐次命中
- v5.0 (2026-09-11): §1.2 補模擬視窗的換算比例；新增 §1.2.1 改過模擬尺寸必須 reload 元件才重新掛載、
  §1.8 一輪測試最容易燒掉時間的四件事、§1.9 下拉浮層關閉動畫期間 `pointer-events: none`
- v4.0 (2026-09-10): §1 重構為「ref 為預設操作路徑、座標為備案」，並補上兩條路線各自的回合成本；
  §3 盤點批次加入 `read_page filter:"all"` 取整頁 ref；§4 改列 ref 路線 2 回合與座標路線 3 回合的寫法；
  畫面繪製救援降級為 §1.5 異常處理，處置第 1 步改為請使用者把視窗帶到前景
