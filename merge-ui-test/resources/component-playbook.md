# 元件操作手冊

**證據等級標示**：`[實測]` = 在 `sndams.ds88.tw`（飛龍測試後台，React 18 ＋ Ant Design v5，
前綴 `custom-modal-`）實地驗證過；`[通例]` = Ant Design 的一般行為，套用前需在該站複驗一次。

選擇器一律用**後綴比對**（`[class*=select-selector]`），不要寫死前綴。

## 0. 盤點探針

掃出頁面上所有可互動元件，產計畫書 §3.2 的盤點表：

```js
const q=s=>[...document.querySelectorAll(s)];
({
  buttons: q('button').map(e=>({txt:(e.innerText||'').trim(), type:e.type,
                                cls:String(e.className).slice(0,50)})).filter(b=>b.txt),
  // 用 token 比對過濾，避免命中 -select-selection-search 之類的內層元素
  selects: q('[class*=-select]').filter(e=>[...e.classList].some(c=>/-select$/.test(c)))
    .map(e=>({label:(e.closest('[class*=form-item]')||{}).innerText,
              value:(e.querySelector('[class*=selection-item]')||{}).innerText,
              placeholder:(e.querySelector('[class*=selection-placeholder]')||{}).innerText,
              multiple:/select-multiple/.test(e.className),
              id:(e.querySelector('[role=combobox]')||{}).id})),
  inputs: q('input[type=text],input[type=number],input:not([type])')
    .map(e=>({id:e.id, ph:e.placeholder, cls:String(e.className).slice(0,40)})),
  radios: q('[class*=radio-wrapper]').map(e=>({txt:(e.innerText||'').trim(),
                                               checked:!!e.querySelector('input:checked')})),
  pickers: q('[class*=-picker]').map(e=>({ph:(e.querySelector('input')||{}).placeholder})),
  tabs: q('[class*=tabs-tab],[class*=collapse-header]').map(e=>(e.innerText||'').trim().slice(0,20))
})
```

## 1. Select（下拉選單）

### 點擊目標：combobox input，不是 selector、不是 placeholder

`[role=combobox]` 那個 `input` 是**唯一可靠的點擊目標**，單選與多選皆同 `[實測]`。

| 目標 | 結果 | 證據 |
|---|---|---|
| `[role=combobox]` 的 input | ✅ 展開 | 單選（登入頁語言）與多選（`#data_WM_Baccarat`）皆實測成功 |
| `[class*=select-selector]` 的中心 | ❌ 無反應 | 多選時中心落在 `selection-overflow`，點了不觸發 |
| `[class*=selection-placeholder]` | ❌ 無反應 | `getComputedStyle` 實測 `pointer-events: none`。`find("請選擇")` 回傳的正是它 |

input 寬度可能只有 4px（多選未輸入時實測 `w:4`，且位置在選單框最左端而非中央），
**不要用選單框的中心座標**，要用 input 自己的 `getBoundingClientRect()`，
再依 `browser-recipes.md` §1 換算成截圖座標系。

選項節點沒有 `role="option"`、沒有 `id` `[實測]`，AX tree 看不到，`find` 也定位不到。

### 定位 Select 容器

`closest('[class*=-select]')` **會命中內層**的 `-select-selection-search` 等元素 `[實測]`，
抓不到真正的容器。要用 token 比對：

```js
const selectRoot = el => { let n = el;
  while (n && !([...n.classList].some(c => /-select$/.test(c)))) n = n.parentElement;
  return n; };
```

### 開啟前的前置檢查

```js
const c = document.querySelector('#某個 combobox 的 id');   // 或由 selectRoot 往下找
const sel = selectRoot(c);
c.scrollIntoView({block:'center'});
const r = c.getBoundingClientRect();
const cx = Math.round(r.x+r.width/2), cy = Math.round(r.y+r.height/2);
({ center: [cx, cy],
   disabled: /select-disabled/.test(sel.className),
   // 判準是「命中點落在同一個 Select 容器內」，不是「等於 combobox 本身」
   inSameSelect: sel.contains(document.elementFromPoint(cx, cy)) })   // false 才別點
```

已有值的 Select，`selection-item`（顯示值那個 span）會蓋在 combobox 上方 `[實測]`，
此時 `elementFromPoint !== combobox` 但**點下去照樣有效**——它屬於同一個控制項。
只有命中點落到 Select 容器**之外**時才是真的被遮蔽（常見於 pane 過窄時側邊選單抽屜覆蓋表單）
`[實測]`，那才要先解決遮蔽再點。

座標記得依 `browser-recipes.md` §1 換算成截圖座標系。

### 開啟後必須驗明身分

一頁有 20 個外觀相同的 Select 時，點錯位置會開到**別的** Select，而選項讀起來一樣像模像樣。
用 `aria-owns` 對應的 list id 確認開的是不是目標 `[實測]`：

```js
const c = document.querySelector('#目標 combobox 的 id');
const listId = c.getAttribute('aria-owns');          // 例：data_WM_Baccarat_list
const mine = [...document.querySelectorAll('[class*=select-dropdown]')]
  .filter(x => !/dropdown-hidden/.test(x.className))
  .find(x => x.querySelector('#' + CSS.escape(listId)));
({ isTarget: !!mine })                                // false 就是開錯了
```

**沒做這一步就記錄選項內容，等於在寫別人的資料。**

### 讀取選項

下拉浮層 portal 到 `body` 的孫層 `[實測]`，不在觸發元素底下：

```js
const d = [...document.querySelectorAll('[class*=select-dropdown]')]
          .filter(x => !/dropdown-hidden/.test(x.className))[0];
const opts = [...d.querySelectorAll('[class*=select-item-option][aria-selected]')];
const v = d.querySelector('.rc-virtual-list-holder');
({ options: opts.map(e=>e.innerText.trim()),
   truncated: v && v.scrollHeight > v.clientHeight })   // true = 還有沒渲染出來的選項
```

- **必須帶 `[aria-selected]`**：每個選項有 3 個 DOM 節點（32px 真 option ＋ 22px content span
  ＋ 空節點），只有真 option 帶這個屬性 `[實測]`。用純文字比對會抓到內層 span。
- **虛擬滾動會截斷** `[實測]`：實測 `scrollHeight 608 / clientHeight 256`，24 個選項只渲染 10 個。
  `truncated === true` 時要選後面的選項，**先在 combobox 打字過濾**，不要盲目捲動。

### 驗證選取結果

**另起一次呼叫**再驗（React 18 批次更新，同批次讀到舊值 `[實測]`）：

```js
({ selected: [...sel.querySelectorAll('[class*=selection-item]')].map(e=>e.innerText.trim()),
   stillOpen: /select-open/.test(sel.className),
   placeholderGone: !sel.querySelector('[class*=selection-placeholder]') })
```

**`aria-expanded` 不可當成功訊號** `[實測]`：實際已展開、選項讀得到時，該屬性仍可能停在
`"false"`。可靠訊號是「存在未帶 `-hidden` 的 dropdown、通過身分驗明、且讀得到選項」。

**`Escape` 關不掉下拉** `[實測]`，`document.body.click()` 也不行。開著的浮層會蓋住後續操作
區域並造成誤點，收尾時直接 `navigate` 重載頁面最乾淨。

「下拉關閉」不等於「有選到」——關閉也可能是點在浮層外把它關掉了 `[實測]`。
**必須看到 `selected` 有值才算成功。**

## 2. Button（按鈕）

| 陷阱 | 證據 |
|---|---|
| 兩個中文字的按鈕，antd 會插入空白 | `[實測]` `find("提交")` 無結果，實際文字是「提 交」。用 `find("提")` 或 `type="submit"` 定位 |
| 圖示按鈕沒有 accessible name | `[實測]` 登入按鈕在 AX tree 是 `button` ＋ `img "login"`，`find("登入")` 找不到 |

定位建議：優先用 `type`（`submit`）、`id`，其次用 `innerText` 去空白後比對，
最後才用 `find`。

## 2.5 定位錨點的穩定性

`rc_select_N` 這類自動編號 id **跨渲染會變** `[實測]`：同一個語言選單前後兩次載入分別是
`rc_select_22` 與 `rc_select_0`。**不可當錨點。**

穩定的是語意 id：`memId`、`name`、`point`、`cagent_uid`、`game_rebate_{平台id}`、
`data_{平台}_{遊戲}`。沒有語意 id 的元件（例如頁首語言選單）改用「值或鄰近文字」定位。

## 3. Form 欄位

`[實測]` 表單 input 帶穩定 `id`（`memId`、`name`、`point`、`game_rebate_{平台id}`、
`data_{平台}_{遊戲}`）。**這是本站最可靠的定位錨點**，也是策略 C（Re-test 腳本化）的基礎——
盤點時務必把 id 記進頁面文件的操作步驟章節。

**輸入完成後、觸發送出之前必須留等待。** `computer type` 之後立刻點「搜索」「提交」，
React 尚未 commit 表單狀態，送出的會是**舊值**——請求少帶參數、結果不符預期，而且**不會報錯**，
看起來完全像功能壞掉 `[實測]`。

實測案例：會員登入日誌頁填入玩家帳號後立刻按搜索，請求未帶 `memId`、回傳全部 13 筆；
補上等待後同一操作正確送出 `&memId=testwinwin01`、回傳 4 筆。**差點誤報成 FAIL。**

判定紀律：任何「填欄位 → 送出」的操作，送出前要先讀一次欄位值確認已 commit，
或在 `type` 與送出之間插入 `wait`。**沒做到就不得據此判 `FAIL`。**

**輸入前必須先清空。** `computer type` 是附加而非取代：實測 `#point` 原有預設值 `0`，
直接輸入 `500` 得到 `"0500"` `[實測]`。點擊欄位後先 `key` 送 `ctrl+a`（或確認欄位為空）
再輸入，並在驗證時**比對完整值**而非只看「有沒有字」。

`form_input` 對原生 `input` 有效；對 antd Select 無效（不是原生 `<select>`，直接設值不會
觸發 React onChange）`[通例]`。

## 4. Modal / Drawer

- 關閉後 DOM 可能殘留，用 `[class*=modal-wrap]` 的可見性判定，不要只看元素存在 `[通例]`。
- 同時開多個浮層時，`querySelectorAll` 取**最後一個**未帶 `-hidden` 的才是當前那個 `[實測]`。
- Drawer 在窄 viewport 下會覆蓋主內容並攔截所有點擊 `[實測]`。

## 5. Table（含 Pro Table）

- fixed column 會產生兩份 DOM，同一顆操作按鈕出現兩次 `[通例]`；取 ref 前先確認數量。
- 「欄位設定、顯示密度、每頁筆數的畫面切換」依計畫書 §4.5 屬純前端，判定填 `N/A`。
- **列內操作連結未必是 `button` 或 `a`**：實測棄分記錄的「查看」是
  `<p class="text-blue-500 cursor-pointer">` `[實測]`，無障礙樹不歸類為可互動元素，
  `read_page` 與 `find` 都定位不到。改用 `tbody p` 等結構選擇器搭配文字比對。
- 分頁資訊（「第 1-3 條/總共 3 條」）可與 API 的 `pagination.total_records` 交叉驗證 `[實測]`。
- 分頁會發 API，列入測試範圍。

## 6. DatePicker / RangePicker

**改日期最省事的做法是直接改輸入框，不必開日曆浮層** `[實測]`：

```
triple_click 該 input  →  type "2026-07-12"  →  key Enter
```

**`ctrl+a` 對 DatePicker 的 input 無效** `[實測]`：不會全選，輸入會插進原值中間，
實測得到 `2026-09-02026-07-129` 這種混合字串。**一律用 `triple_click` 全選。**

改完起日後，訖日可能被元件自動調整成別的值（實測從 `2026-09-10` 變成 `2026-08-21`），
**兩個欄位都要各自設定並在送出前重讀確認**。

浮層在 `[class*=picker-dropdown]`，portal 到 body；設定完成後浮層可能仍開著，
取後續按鈕座標前要確認沒有被浮層遮住。

快捷鍵（今日／昨日／本周／上周／本月／上月）不發請求，只填入欄位，需另按「搜索」才送出，
依計畫書 §4.5 判 `N/A` `[實測]`。

## 7. Radio / Checkbox

`[實測]` 容器是 `[class*=radio-wrapper]`，選中態看內層 `input:checked`。

點擊目標用 **wrapper 的文字區**（例 `x + width*0.75`），不要點 `input`——它 `opacity: 0`、
實測只有 8×13px `[實測]`。座標一樣要換算成截圖座標系。

`read_page` 的 `filter:"interactive"` 會漏掉 checkbox，要用 `filter:"all"`。

**Radio 可能不是純前端**：`create-player` 的「創建對象」切到「紙鈔機臺」會整份抽換表單欄位
（玩家帳號／暱稱／點數 → 機臺所在區域／MAC 地址／Anydesk 登入位址與密碼）並觸發 API `[實測]`。
盤點時不可因為「看起來像切換」就填 `N/A`，要依計畫書 §4.5 實際看有沒有發 API。

---
**最後更新**: 2026-09-09
**維護者**: 開發團隊
**文件版本**: v1.7
**變更記錄**（里程碑，最多 5 條）:
- v1.7 (2026-09-09): §6 DatePicker 由通例改為實測——改日期用 `triple_click` ＋ 輸入 ＋ Enter，`ctrl+a` 無效會插入原值中間；訖日可能被自動調整，兩欄都要重讀確認
- v1.6 (2026-09-09): §3 補「送出前必須等 React commit」——實測因未等待而送出舊表單狀態，差點把正常功能誤判為 FAIL
- v1.5 (2026-09-09): §5 補 Pro Table 實測——列內操作連結可能是 `<p>` 而非 `button`／`a`，AX 樹定位不到；分頁資訊可與 API `total_records` 交叉驗證
- v1.4 (2026-09-09): §3 補「輸入前必須清空」——`type` 是附加不是取代，實測預設值 `0` 加輸入 `500` 得到 `0500`
- v1.3 (2026-09-09): 前置檢查判準放寬為「命中點在同一個 Select 容器內」（已有值時 `selection-item` 會蓋住 combobox，但點擊仍有效）；新增 §2.5 定位錨點穩定性——`rc_select_N` 跨渲染會變不可當錨點
- v1.2 (2026-09-09): 補 Select 開啟後以 `aria-owns` 驗明身分（一頁多個同型 Select 會開錯而不自知）；補 `Escape` 關不掉下拉；§7 補 Radio 點擊目標與「切換可能觸發 API」實例
- v1.1 (2026-09-09): §1 訂正 Select 點擊目標——改為 `[role=combobox]` 的 input（selector 中心在多選時落在 `selection-overflow` 不觸發）；補容器定位需用 class token 比對；`aria-expanded` 不可當成功訊號
- v1.0 (2026-09-08): 建立元件手冊，Select／Button／Form／Modal／Table／Radio 章節以 sndams.ds88.tw 實測資料為據，未驗證項標記為通例
