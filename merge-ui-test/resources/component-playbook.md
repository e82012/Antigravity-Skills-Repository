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
   hitsCombobox: document.elementFromPoint(cx, cy) === c })   // false 就別點
```

`hitsCombobox === false` 代表該座標被別的元素蓋住（常見於 pane 過窄時側邊選單抽屜覆蓋表單）
`[實測]`。**先解決遮蔽再點，不要硬點。**

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

## 3. Form 欄位

`[實測]` 表單 input 帶穩定 `id`（`memId`、`name`、`point`、`game_rebate_{平台id}`、
`data_{平台}_{遊戲}`）。**這是本站最可靠的定位錨點**，也是策略 C（Re-test 腳本化）的基礎——
盤點時務必把 id 記進頁面文件的操作步驟章節。

`form_input` 對原生 `input` 有效；對 antd Select 無效（不是原生 `<select>`，直接設值不會
觸發 React onChange）`[通例]`。

## 4. Modal / Drawer

- 關閉後 DOM 可能殘留，用 `[class*=modal-wrap]` 的可見性判定，不要只看元素存在 `[通例]`。
- 同時開多個浮層時，`querySelectorAll` 取**最後一個**未帶 `-hidden` 的才是當前那個 `[實測]`。
- Drawer 在窄 viewport 下會覆蓋主內容並攔截所有點擊 `[實測]`。

## 5. Table（含 Pro Table）

- fixed column 會產生兩份 DOM，同一顆操作按鈕出現兩次 `[通例]`；取 ref 前先確認數量。
- 「欄位設定、顯示密度、每頁筆數的畫面切換」依計畫書 §4.5 屬純前端，判定填 `N/A`。
- 分頁會發 API，列入測試範圍。

## 6. DatePicker / RangePicker

`[通例]`（本站尚未驗證）：浮層在 `[class*=picker-dropdown]`，同樣 portal 到 body。
快捷鍵（今日／本週／本月）若改變查詢參數並送出，依計畫書 §4.5 界線**列入測試範圍**。

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
**文件版本**: v1.2
**變更記錄**（里程碑，最多 5 條）:
- v1.2 (2026-09-09): 補 Select 開啟後以 `aria-owns` 驗明身分（一頁多個同型 Select 會開錯而不自知）；補 `Escape` 關不掉下拉；§7 補 Radio 點擊目標與「切換可能觸發 API」實例
- v1.1 (2026-09-09): §1 訂正 Select 點擊目標——改為 `[role=combobox]` 的 input（selector 中心在多選時落在 `selection-overflow` 不觸發）；補容器定位需用 class token 比對；`aria-expanded` 不可當成功訊號
- v1.0 (2026-09-08): 建立元件手冊，Select／Button／Form／Modal／Table／Radio 章節以 sndams.ds88.tw 實測資料為據，未驗證項標記為通例
