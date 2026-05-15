---
name: FRONTEND-ENGINEERING (前端工程技巧)
description: 專注於前端性能優化、CSS 架構、互動模式、響應式工程與無障礙實作
---

# 前端工程技巧 (Frontend Engineering)

> **Version:** 1.0
> **Last Updated:** 2026-05-15
> **定位：** 性能、工程實踐、互動模式、響應式、CSS 架構、無障礙工程
> **姊妹 Skill：** `ui-skill` — 負責視覺美化、色彩、排版、動效美學

---

## 1. CSS 架構與隔離 (CSS Architecture & Isolation)

### 樣式復用
- **原子化 Class 優先**：強制使用專案現有的 Tailwind/CSS Class。撰寫前必須掃描現有樣式，嚴禁重複造輪子。
- **組件庫優先**：優先使用專案已有的 UI Kit（如 Shadcn UI, AntD, Radix），確保行為邏輯一致。
- **Token 系統**：使用兩層 Token — primitive tokens（`--blue-500`）和 semantic tokens（`--color-primary: var(--blue-500)`）。主題切換只重定義 semantic 層。

### 工程隔離
- **命名衝突預防**：新增 Class 或組件前需全域搜索，確保不與現有樣式衝突。
- **技術隔離策略**：優先使用 CSS Modules 或 Tailwind 的 `@layer` 指令。
- **Alpha 是設計味道**：大量使用透明度（rgba, hsla）通常代表調色板不完整。為每個場景定義明確的覆蓋色，而非依賴透明度疊加。例外：Focus ring 和互動狀態。

### 防禦性 CSS (Robustness)
- 動態文字區塊必須考慮溢出：強制使用 `truncate` 或 `line-clamp`
- 容器應具備 `min-h` 或 `aspect-ratio` 以防止 Layout Shift
- **只動 `transform` 和 `opacity`**：其他屬性會觸發 layout recalculation。高度動畫用 `grid-template-rows: 0fr → 1fr` 替代直接動畫 `height`
- 過渡效果應限制在特定屬性（如 `transition-colors`），而非全域 `transition-all`

---

## 2. 互動模式 (Interaction Patterns)

### 八種互動狀態

每個互動元素都需要設計這些狀態：

| 狀態 | 觸發時機 | 視覺處理 |
|------|---------|---------|
| **Default** | 靜止 | 基礎樣式 |
| **Hover** | 指標移入（非觸控） | 微幅提升、色彩變化 |
| **Focus** | 鍵盤/程式焦點 | 可見焦點環 |
| **Active** | 正在按壓 | 按入感、加深 |
| **Disabled** | 不可互動 | 降低透明度、禁止指標 |
| **Loading** | 處理中 | Spinner、Skeleton |
| **Error** | 錯誤狀態 | 紅色邊框、圖示、訊息 |
| **Success** | 完成 | 綠色確認 |

**關鍵：** Hover 和 Focus 是不同的。鍵盤使用者永遠看不到 hover 狀態。

### Focus Ring 正確做法

**絕對禁止 `outline: none` 而不提供替代方案。** 使用 `:focus-visible` 只對鍵盤使用者顯示焦點環：

```css
button:focus { outline: none; }
button:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}
```

**設計要求**：對比度至少 3:1、2-3px 粗、偏移元素外側、全站一致。

### 表單設計
- **Placeholder 不是 Label**：Placeholder 會在輸入時消失，必須使用可見的 `<label>`
- **Blur 時驗證**，而非每次按鍵（例外：密碼強度即時回饋）
- 錯誤訊息放在欄位**下方**，使用 `aria-describedby` 連結

### Modal：使用 `inert` 屬性

```html
<!-- Modal 開啟時 -->
<main inert><!-- 背景內容無法被 focus 或點擊 --></main>
<dialog open>
  <h2>Modal Title</h2>
  <!-- Focus 被困在 modal 內 -->
</dialog>
```

或使用原生 `<dialog>` 元素：`dialog.showModal()` — 自帶 focus trap，按 Escape 可關閉。

### Popover API

Tooltip、Dropdown、非模態覆蓋層，使用原生 Popover：

```html
<button popovertarget="menu">Open menu</button>
<div id="menu" popover>
  <button>Option 1</button>
  <button>Option 2</button>
</div>
```

**優勢**：Light-dismiss、正確堆疊、無 z-index 戰爭、預設無障礙。

### 鍵盤導航

**Roving Tabindex**：組件群組（tabs, menu, radio）中只有一項可 Tab，箭頭鍵在內部移動：

```html
<div role="tablist">
  <button role="tab" tabindex="0">Tab 1</button>
  <button role="tab" tabindex="-1">Tab 2</button>
  <button role="tab" tabindex="-1">Tab 3</button>
</div>
```

**Skip Links**：提供 `<a href="#main-content">Skip to main content</a>` 讓鍵盤使用者跳過導航列。

### 破壞性操作：Undo > Confirm

**Undo 優於確認對話框**——使用者會無意識地點過確認。從 UI 立即移除、顯示 Undo Toast、Toast 過期後才真正刪除。僅在真正不可逆操作（帳號刪除）、高成本操作、批次操作時使用確認。

### 手勢可發現性

滑動刪除等手勢是隱形的。提示其存在：
- 局部顯露刪除按鈕
- 首次使用時的引導標記
- **永遠提供可見的備選操作**（如選單中的「刪除」）

---

## 3. 響應式工程 (Responsive Engineering)

### Mobile-First
從手機基礎樣式開始，使用 `min-width` 查詢逐步添加複雜度。Desktop-first（`max-width`）意味著手機先載入不需要的樣式。

### 內容驅動斷點
別追逐裝置尺寸——從窄開始拉伸，設計破掉的地方加斷點。三個斷點通常就夠（640, 768, 1024px）。使用 `clamp()` 實現無斷點的流體值。

### 偵測輸入方式，而非螢幕尺寸

```css
/* 精確指標（滑鼠、觸控板） */
@media (pointer: fine) { .button { padding: 8px 16px; } }

/* 粗略指標（觸控） */
@media (pointer: coarse) { .button { padding: 12px 20px; } }

/* 支援 hover 的裝置 */
@media (hover: hover) { .card:hover { transform: translateY(-2px); } }

/* 不支援 hover（觸控裝置） */
@media (hover: none) { .card { /* 使用 active 替代 */ } }
```

**關鍵**：不要依賴 hover 實現功能。觸控使用者無法 hover。

### Safe Areas

```css
body {
  padding-top: env(safe-area-inset-top);
  padding-bottom: env(safe-area-inset-bottom);
  padding-left: env(safe-area-inset-left);
  padding-right: env(safe-area-inset-right);
}
```

```html
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
```

### 響應式圖片

```html
<img src="hero-800.jpg"
  srcset="hero-400.jpg 400w, hero-800.jpg 800w, hero-1200.jpg 1200w"
  sizes="(max-width: 768px) 100vw, 50vw"
  alt="Hero image">
```

Art Direction 用 `<picture>` 元素（不同裁切，非只是解析度差異）。

### Container Queries

Viewport 查詢用於頁面佈局，**Container Queries 用於組件**：

```css
.card-container { container-type: inline-size; }

@container (min-width: 400px) {
  .card { grid-template-columns: 120px 1fr; }
}
```

### 導航自適應
三階段——手機：Hamburger + Drawer → 平板：水平精簡 → 桌面：完整含標籤。表格在手機上用 `display: block` + `data-label` 轉為卡片。使用 `<details>/<summary>` 實現漸進式揭露。

### 測試
DevTools 裝置模擬會遺漏：真實觸控互動、實際 CPU/記憶體限制、網路延遲、字型渲染差異、瀏覽器 Chrome/鍵盤外觀。**至少在一台 iPhone、一台 Android、相關時加上平板上測試。**

---

## 4. 動效性能 (Motion Performance)

### 動畫效能規則
- **只動 `transform` 和 `opacity`**：其他屬性觸發 layout recalculation
- 高度動畫用 `grid-template-rows: 0fr → 1fr`
- `will-change` 不要預防性使用——只在動畫即將發生時（`:hover`、`.animating`）
- 滾動觸發動畫用 **Intersection Observer** 替代 scroll events；動畫完成後 `unobserve`
- 建立 motion tokens 以維持一致性（duration、easing、常用 transition）

### Staggered Animations 效能
```css
animation-delay: calc(var(--i, 0) * 50ms);
```
**限制總 stagger 時間**：10 項 × 50ms = 500ms。項目多時減少每項延遲或限制 stagger 數量。

### Reduced Motion（必要，非可選）

前庭功能障礙影響 ~35% 40 歲以上成人。

```css
@media (prefers-reduced-motion: reduce) {
  .card { animation: fade-in 200ms ease-out; /* 用淡入替代空間移動 */ }
}
```

**保留的功能動畫**：進度條、載入指示器（減速）、焦點指示器——只是移除空間移動。

---

## 5. 字型載入性能 (Font Loading Performance)

### 避免 Layout Shift

```css
@font-face {
  font-family: 'CustomFont';
  src: url('font.woff2') format('woff2');
  font-display: swap;
}

/* 匹配 Fallback 指標以最小化 shift */
@font-face {
  font-family: 'CustomFont-Fallback';
  src: local('Arial');
  size-adjust: 105%;
  ascent-override: 90%;
  descent-override: 20%;
  line-gap-override: 10%;
}

body { font-family: 'CustomFont', 'CustomFont-Fallback', sans-serif; }
```

工具：[Fontaine](https://github.com/unjs/fontaine) 可自動計算 override 值。

### 系統字型
`-apple-system, BlinkMacSystemFont, "Segoe UI", system-ui` — 原生外觀、即時載入、高可讀性。當效能 > 個性時優先考慮。

---

## 6. 無障礙工程 (Accessibility Engineering)

### WCAG 對比度要求

| 內容類型 | AA 最低 | AAA 目標 |
|---------|--------|---------|
| 正文文字 | 4.5:1 | 7:1 |
| 大文字（18px+ 或 14px 粗體） | 3:1 | 4.5:1 |
| UI 組件、圖示 | 3:1 | 4.5:1 |
| 非必要裝飾 | 無 | 無 |

**注意**：Placeholder 文字仍需 4.5:1 對比度。

### 危險色彩組合
- 淺灰色文字 + 白色背景（#1 無障礙違規）
- 灰色文字 + 任何彩色背景（看起來灰暗死板）
- 紅色 + 綠色（8% 男性無法區分）
- 藍色 + 紅色（視覺振動）
- 黃色 + 白色（幾乎必然不合格）

### 基礎要求
- **禁止 `user-scalable=no`**：若 200% 縮放時佈局破裂，修復佈局
- **字型用 `rem/em`**，尊重使用者瀏覽器設定，正文禁用 `px`
- **正文最小 16px**：更小會造成閱讀壓力
- **觸控目標至少 44×44px**：文字連結需透過 padding 或 line-height 達到
- **語義化標籤**：優先使用 `<nav>`, `<article>`, `<aside>`, `<main>`
- **Link 文字**需有獨立含義：「查看定價方案」而非「點擊這裡」
- **Alt 文字**描述資訊而非圖片：「Q4 營收增長 40%」而非「圖表」
- 裝飾性圖片使用 `alt=""`
- Icon button 需要 `aria-label`

### 色覺障礙測試
使用瀏覽器 DevTools → Rendering → Emulate vision deficiencies。[WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/) 進行對比度驗證。

---

**禁止**：移除焦點指示器而不提供替代。用 Placeholder 當 Label。觸控目標 < 44px。泛用錯誤訊息。自訂控件缺少 ARIA/鍵盤支援。Desktop-first 設計。分離行動版/桌面版程式碼。