# 排障：點不到、讀不到、判不了

## 降級順序

**第 1 級是預設路徑，不是備案。** 每一頁進來就先取一次整頁 ref，所有操作都從第 1 級起跳；
元件操作失敗時才**照順序往下試，不得跳級**。每一級都要驗證狀態變化，不是看工具回報。

| 級 | 手段 | 回合成本 | UI 層可否判 `PASS` |
|---|---|---|---|
| 1 | `read_page` `filter:"all"` 取 ref → `computer` 點擊 | 1 | 可 |
| 2 | DOM 探針算出目標中心座標 → 先 `screenshot` → `computer` 座標點擊 | 3 | 可 |
| 3 | 鍵盤路徑：focus 目標 → `key` 操作（Enter 展開、方向鍵選、Enter 確認） | 2 | 可 |
| 4 | `javascript_tool` dispatch 滑鼠事件 | 2 | **不可，填 `⚠️`** |
| 5 | `javascript_tool` 直接改 DOM／React state | 2 | **不可，填 `⚠️`** |

第 4、5 級繞過的是 UI 層，測到的只有 API 與 DB。說明欄必須寫「以 JS 降級操作」。

**同一元件失敗 3 次即停止**（計畫書 §8 第 7 條），標 `BLOCKED`，輸出：
已嘗試的手段清單、每次的實際觀測值、建議使用者介入的具體操作點。

## 症狀對照表

| 症狀 | 先查這個 | 依據 |
|---|---|---|
| 整個搜索條件區／某個區塊不存在 | **先查 `innerWidth` 是否為 0**。視窗被遮蔽時頁面不繪製，RWD 會以極小螢幕掛載。判為功能缺漏前必須先在繪製狀態下重載一次 | `browser-recipes.md` §1 |
| 截圖回報 did not finish rendering | 同上，Claude 視窗被其他視窗蓋住 | `browser-recipes.md` §1 |
| 點擊落空但座標「剛才還是對的」 | 中間有動作改變了版面（結果筆數、彈窗、欄位增減），座標已失效，重新取 | `browser-recipes.md` §1 |
| 送出後參數少帶、結果像壞掉 | `type` 與送出之間沒等 React commit，送的是舊表單狀態。**先排除這個再判 FAIL** | `component-playbook.md` §3 |
| 點擊落在頁面下方另一個元件上 | 座標忘了換算成截圖座標系（最常見的一條） | `browser-recipes.md` §1 |
| 讀到的選項內容怪怪的 | 是不是開到別的同型 Select，用 `aria-owns` 驗明身分 | `component-playbook.md` §1 |
| `window.scrollTo` 沒作用 | 捲動容器不是 `window`，改用 `scrollIntoView` | `browser-recipes.md` §1 |
| 下拉關不掉、擋住後續操作 | `Escape` 與 `body.click()` 都無效，直接 `navigate` 重載 | `component-playbook.md` §1 |
| Select 點了完全沒反應 | 目標是不是 selector 中心或 placeholder；正解是 `[role=combobox]` 的 input | `component-playbook.md` §1 |
| 工具回報已點擊，頁面毫無反應 | 目標是不是 `[class*=selection-placeholder]`（`pointer-events: none`） | `component-playbook.md` §1 |
| 點擊落在完全無關的元件上 | `document.elementFromPoint(cx,cy)` 是不是被側邊選單抽屜蓋住；pane 是否過窄 | `browser-recipes.md` §1 |
| 每次點擊前都在截圖、算座標 | 走錯路線了。改用 `read_page` `filter:"all"` 的 `ref` 點擊，不需截圖也不需換算 | `browser-recipes.md` §1.1 |
| 不確定座標要不要換算 | 要。`coordinate` 吃的是截圖座標系，只有 frame 與 viewport 剛好 1:1 時才等同頁面座標 | `browser-recipes.md` §1.2、§1.7 |
| 狀態讀出來永遠是舊值 | 讀取是不是跟點擊在同一次呼叫內（React 18 批次更新）；`aria-expanded` 本身就不可靠 | `SKILL.md` 紀律 2 |
| `find` 找不到明明看得到的按鈕 | antd 兩字按鈕會插空白（「提 交」）；圖示按鈕沒有 accessible name | `component-playbook.md` §2 |
| `read_page` 少了 combobox／checkbox | 用了 `filter:"interactive"`，改 `filter:"all"` | `browser-recipes.md` |
| 下拉開了但找不到選項 | 浮層 portal 到 body，且選項需帶 `[aria-selected]` 過濾 | `component-playbook.md` §1 |
| 選項清單比畫面上少 | 虛擬滾動截斷，查 `scrollHeight > clientHeight`，改用打字過濾 | `component-playbook.md` §1 |
| 選擇器整個對不上 | 該站前綴不同（已知有 `custom-modal-`／`ant-` 混用），跑環境探針重取 | `browser-recipes.md` §0 |
| 捲動後點擊還是打在舊位置 | `scroll_to` 不更新既有 ref 座標，重跑 `find`／`read_page` | `browser-recipes.md` §1 |
| 導覽後所有 ref 都失效 | `navigate` 會重新編號 ref | `browser-recipes.md` §1 |
| 座標點擊直接報錯 | 帶 `coordinate` 前必須先 `screenshot` | `browser-recipes.md` §1 |

## 什麼時候該標 BLOCKED 而不是繼續繞

符合任一條就停下標 `BLOCKED`，寫清楚缺什麼：

- 需要的測試對象不存在（例：要測機臺工具但手上帳號不是機臺玩家）。
- 畫面反覆無法繪製（`innerWidth` 為 0、截圖逾時），已請使用者把視窗帶到前景仍未改善。
- 前置條件無法對齊（計畫書 §5.2 的相同條件不成立）。
- 監聽器未及時掛上（計畫書 §1.4）。
- pane 尺寸不足導致版面錯亂，且使用者尚未拉寬。
- 降級到第 3 級仍失敗。

**不得用「畫面看起來成功」代替驗證**，也不得因為繞不過去就把項目悄悄跳過。

## 未解項（待後續補齊）

| 項目 | 現況 | 下一步 |
|---|---|---|
| Pro Table fixed column 雙份 DOM | 未在本站驗證 | 測玩家查詢／代理查詢時補校準 |

## 「按了沒反應」的三個查證點

判定按鈕失效前，依序排除這三項。實測每一項都各自造成過一次誤判：

**1. 有東西蓋在按鈕上。** 通知彈窗、下拉選單的遮罩會覆蓋頁尾按鈕。
`document.elementFromPoint(cx, cy)` 回傳的不是按鈕（或其內層 `span`）就是被蓋住了，先把它關掉。
實測：某站空表單送出回報「0 個欄位報錯」，看起來像少了驗證，
其實是站內信通知彈窗壓在提交鈕上——關掉後兩站同為 2 個欄位報錯。

**2. 請求送出了，但失敗訊息只在 toast。** 表單驗證失敗未必寫進 `form-item-explain`。
檢查 `has-error` 是空的、卻覺得「按了沒動作」時，先讀 toast：

```js
[...new Set([...document.querySelectorAll('[class*=message-notice]')]
  .map(x => x.innerText.trim().replace(/\s+/g, ' ')))].filter(Boolean)
```

實測：連按三次都沒生效，`has-error` 全空，看起來像按鈕壞了；
掛上 XHR 觀察器才發現每次都送出了 `PUT` 並回 422，
訊息只在 toast——**是測試值本身不合格式**（暱稱含連字號），不是站別差異也不是按鈕問題。

**3. 版面在上一次操作後位移了。** 提交會改變頁面高度，舊座標會落空。
每次點擊前重新量，不要沿用上一輪的值。

順序很重要：先確認點得到（1），再確認送出了沒（2），最後才懷疑功能本身。

## 同一頁兩種進入方式，結果可能不同

由清單點進明細，和直接開明細網址，走的是不同的資料來源——
前者可能沿用清單傳入的狀態，後者才會自己打 API。

實測：某明細頁由清單進入時所有欄位顯示 `-`、狀態還顯示反了，
直接開同一個網址則完全正常，而 API 兩種情況都回完整資料。

**盤點明細頁時兩種路徑都要走一次**，只測其中一種會漏掉這類缺陷，
或反過來把正常功能誤記成壞的。

## 元素「看不到」不一定是 `display:none`

檢查可見性時只看 `display` 與 `visibility` 會漏掉一種：
整條祖先鏈的 `display` 都是 `block`／`flex`、`visibility` 都是 `visible`，
但每一層的 `getBoundingClientRect()` 寬高都是 0——元素確實在 DOM 裡、樣式看起來也正常，
卻永遠看不到也點不到。

實測：某設定欄位已帶入 2011 字元的值，`display` 一路正常，量出來卻是 0×0；
只查 `display` 會判成「欄位存在且正常」，實際上使用者根本碰不到它。

**判可見性以 `getBoundingClientRect()` 的寬高為準**，樣式屬性只用來解釋原因：

```js
let p = el, chain = [];
for (let i = 0; i < 6 && p; i++) {
  const cs = getComputedStyle(p), r = p.getBoundingClientRect();
  chain.push({tag: p.tagName, display: cs.display, vis: cs.visibility,
              w: Math.round(r.width), h: Math.round(r.height)});
  p = p.parentElement;
}
```

哪一層開始變成 0，版面問題就出在那一層。

## 寬表格：座標超出框寬會靜默失效

座標框只有 800 寬。欄位多的表格（十欄以上）列尾的操作連結，
換算後的 x 會逼近或超過 800——點擊不會報錯，就是沒反應。

實測：某清單有 10–11 欄，列尾「查看」算出 x=794，連點都沒導航；
把元素**橫向**捲進視野後重新換算，x 變成 735 才點得到。

`scrollIntoView` 預設只處理垂直方向，寬表格要兩軸一起捲：

```js
el.scrollIntoView({block: 'center', inline: 'center'});
await new Promise(r => setTimeout(r, 800));
const q = el.getBoundingClientRect();   // 捲完再換算
```

量到的 x 接近 800 時就該警覺，先捲再點。

---
**最後更新**: 2026-09-10
**維護者**: 開發團隊
**文件版本**: v3.0
**變更記錄**（里程碑，最多 5 條）:
- v3.0 (2026-09-10): 降級順序補上各級回合成本，並明訂第 1 級（ref）是預設路徑而非備案；
  訂正 (2026-09-10): 症狀表「想用截圖尺寸換算點擊座標／不需要換算」一條與 `browser-recipes.md` §1.2 相互矛盾，
  更正為「座標一律需換算，改用 ref 才能免除截圖與換算」
- v2.2 (2026-09-10): 新增「寬表格座標超出框寬會靜默失效」——列尾操作連結需以 inline:center 橫向捲入後再換算座標
- v2.1 (2026-09-10): 新增「元素看不到不一定是 display:none」——祖先鏈樣式全正常但量到 0×0，可見性要以 getBoundingClientRect 為準
- v2.0 (2026-09-10): 新增「按了沒反應的三個查證點」（遮擋、toast、版面位移）與「同一頁兩種進入方式結果可能不同」——兩者實測各擋下一次誤判
- v1.0–v1.6 (2026-09-08～09-09): 建立五級降級順序與 UI 判定資格、症狀對照表、BLOCKED 判準；症狀表擴充至座標換算、Select 目標、捲動容器、浮層殘留、繪製失敗等項；DatePicker 以 triple_click 設定日期收斂
