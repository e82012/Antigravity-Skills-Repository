# 排障：點不到、讀不到、判不了

## 降級順序

元件操作失敗時**照順序往下試，不得跳級**。每一級都要驗證狀態變化，不是看工具回報。

| 級 | 手段 | UI 層可否判 `PASS` |
|---|---|---|
| 1 | `read_page` `filter:"all"` 取 ref → `computer` 點擊 | 可 |
| 2 | DOM 探針算出目標中心座標 → 先 `screenshot` → `computer` 座標點擊 | 可 |
| 3 | 鍵盤路徑：focus 目標 → `key` 操作（Enter 展開、方向鍵選、Enter 確認） | 可 |
| 4 | `javascript_tool` dispatch 滑鼠事件 | **不可，填 `⚠️`** |
| 5 | `javascript_tool` 直接改 DOM／React state | **不可，填 `⚠️`** |

第 4、5 級繞過的是 UI 層，測到的只有 API 與 DB。說明欄必須寫「以 JS 降級操作」。

**同一元件失敗 3 次即停止**（計畫書 §8 第 7 條），標 `BLOCKED`，輸出：
已嘗試的手段清單、每次的實際觀測值、建議使用者介入的具體操作點。

## 症狀對照表

| 症狀 | 先查這個 | 依據 |
|---|---|---|
| 點擊落在頁面下方另一個元件上 | 座標忘了換算成截圖座標系（最常見的一條） | `browser-recipes.md` §1 |
| 讀到的選項內容怪怪的 | 是不是開到別的同型 Select，用 `aria-owns` 驗明身分 | `component-playbook.md` §1 |
| `window.scrollTo` 沒作用 | 捲動容器不是 `window`，改用 `scrollIntoView` | `browser-recipes.md` §1 |
| 下拉關不掉、擋住後續操作 | `Escape` 與 `body.click()` 都無效，直接 `navigate` 重載 | `component-playbook.md` §1 |
| Select 點了完全沒反應 | 目標是不是 selector 中心或 placeholder；正解是 `[role=combobox]` 的 input | `component-playbook.md` §1 |
| 工具回報已點擊，頁面毫無反應 | 目標是不是 `[class*=selection-placeholder]`（`pointer-events: none`） | `component-playbook.md` §1 |
| 點擊落在完全無關的元件上 | `document.elementFromPoint(cx,cy)` 是不是被側邊選單抽屜蓋住；pane 是否過窄 | `browser-recipes.md` §1 |
| 想用截圖尺寸換算點擊座標 | 不需要換算，`computer` 直接吃頁面座標 | `browser-recipes.md` §1 |
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
- 前置條件無法對齊（計畫書 §5.2 的相同條件不成立）。
- 監聽器未及時掛上（計畫書 §1.4）。
- pane 尺寸不足導致版面錯亂，且使用者尚未拉寬。
- 降級到第 3 級仍失敗。

**不得用「畫面看起來成功」代替驗證**，也不得因為繞不過去就把項目悄悄跳過。

## 未解項（待後續補齊）

| 項目 | 現況 | 下一步 |
|---|---|---|
| DatePicker／RangePicker 實機行為 | 未驗證，目前只有通例 | 下一頁測到含日期區間的畫面時補校準 |
| Pro Table fixed column 雙份 DOM | 未在本站驗證 | 測玩家查詢／代理查詢時補校準 |

---
**最後更新**: 2026-09-09
**維護者**: 開發團隊
**文件版本**: v1.3
**變更記錄**（里程碑，最多 5 條）:
- v1.3 (2026-09-09): 症狀表補四條（座標未換算、開錯 Select、捲動容器、浮層殘留）
- v1.2 (2026-09-09): 座標系與 Select 點擊兩項未解項收斂——`coordinate` 採截圖座標系須換算，Select 目標為 combobox input；症狀表擴充
- v1.0 (2026-09-08): 建立排障表，訂定五級降級順序與 UI 判定資格、症狀對照表、BLOCKED 判準、未解項登記
