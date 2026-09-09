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

## 1. viewport 與座標

### 座標換算（最重要的一條）

**`computer` 的 `coordinate` 參數採「截圖座標系」，不是頁面 CSS 座標。** 用
`getBoundingClientRect()` 算出的頁面座標直接丟進去會點錯位置，而且**不會報錯**——它會點在
頁面上另一個元件上。

```js
// frameW / frameH 取自截圖回報的 "coordinate frame: {W}x{H}"
const toFrame = (px, py) => [Math.round(px * frameW / innerWidth),
                             Math.round(py * frameH / innerHeight)];
```

`ref` 點擊不需要換算——它由元素解析，直接命中正確目標。**能用 ref 就用 ref。**

實測（viewport 1440×900、frame 800×492）：`#memId` 中心頁面座標 `(202,420)`，直接點會聚焦到
頁面下方 351px 處的 `#game_rebate_LIVE_copy_form`（`420 × 900/492 ≈ 768`）；換算成 `(112,230)`
後才正確命中。

### 捲動

**頁面的捲動容器不是 `window`**（Pro Layout 的內層 content div），`window.scrollTo(0,0)`
無效，`scrollY` 恆為 0。一律用目標元素的 `scrollIntoView({block:'center'})`。

因此**跨視窗的目標不能一次取座標**——捲動後其餘目標就不在可視區了。

### 同視窗多目標批次（實測省 67% 呼叫）

**同時落在可視區內的目標可以一次取完座標，再一批打完。** 實測填 `memId`／`name`／`point`
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

### 開工前必做：確認座標系是 1:1

```
截圖回報的 "coordinate frame: {W}x{H}"  必須等於  JS 讀到的 innerWidth / innerHeight
```

**不相等就代表畫面被縮放（letterbox），此時 ref 與座標點擊都會落在錯誤位置，而且不會報錯**
`[實測]`——工具照樣回報「已點擊」，頁面毫無反應。

不相等的成因通常是 `resize_window` 開了大於 pane 實際尺寸的模擬。**解法不是換算比例**
（letterbox 的比例並非 `frameW / innerWidth`），而是**關掉模擬並請使用者把 Browser pane
實際拉寬**到桌面尺寸。

pane 太窄時後台會觸發 RWD、側邊選單變成抽屜覆蓋整個表單（實測 538×922 即如此），
這時無論怎麼點都會打在遮罩上——**這是環境問題，依 §8 標 `BLOCKED` 並請使用者拉寬 pane，
不要用模擬硬撐。**

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
```

## 4. 操作 ＋ 驗證（階段 B）

**點擊與驗證必須分開兩次呼叫**，React 18 批次更新會讓同批次的讀取拿到舊值。

```
呼叫 1（batch）：scroll 到位 → 取目標座標 → 點擊
呼叫 2（batch）：javascript_tool 驗證狀態 → read_network_requests 取本次 API
```

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

---
**最後更新**: 2026-09-09
**維護者**: 開發團隊
**文件版本**: v1.4
**變更記錄**（里程碑，最多 5 條）:
- v1.4 (2026-09-09): 新增開工前的座標系 1:1 檢查——frame 與 viewport 不相等時畫面被 letterbox，ref 與座標點擊皆失效且不報錯；訂正 v1.2「模擬可放大」的說法
- v1.3 (2026-09-09): 新增「同視窗多目標批次」配方（實測 3 欄位由 6 次呼叫降為 2 次）；註明單一操作回合數下限為 2
- v1.2 (2026-09-09): §1 訂正座標系——`coordinate` 採截圖座標系，須由頁面座標換算（v1.1 寫成頁面座標，實測有誤）；補捲動容器非 `window`、座標不可批次預取、浮層殘留三項
- v1.0 (2026-09-08): 建立配方集，涵蓋環境探針、viewport 與座標事實、雙站 tab、監聽順序、點擊驗證分離、API 落檔、截圖時機
