---
name: UI-SKILL (UI Craftsman & Aesthetic Skill)
description: 融合現代 UI/UX 美學與 Claude-Code 工程規範，專注於高品質、一致性且具備韌性的前端實作
---

# UI 工匠與美學準則 (UI Craftsman & Aesthetic Skill)

## 1. 樣式復用與一致性 (Consistency & Reuse)
- **原子化 Class 優先**：強制使用專案現有的 Tailwind/CSS Class。撰寫前必須掃描現有樣式，嚴禁重複造輪子。
- **組件庫優先**：優先使用專案已有的 UI Kit (如 Shadcn UI, AntD, Radix)，確保行為邏輯一致。
- **配置化色彩**：嚴禁使用隨機 HEX Code。所有顏色必須對應 `theme.colors` 或 Tailwind 預設色階，並確保支援 **Dark Mode (`dark:`)**。

---

## 2. 衝突避免與工程隔離 (Isolation & Safety)
- **命名衝突預防**：新增 Class 或組件前需全域搜索，確保不與現有樣式衝突。
- **技術隔離策略**：優先使用 CSS Modules 或 Tailwind 的 `@layer` 指令。
- **防破版設計 (Robustness)**：動態文字區塊必須考慮溢出情況，強制使用 `truncate` 或 `line-clamp`；容器應具備 `min-h` 或 `aspect-ratio` 以防止 Layout Shift。

---

## 3. 美學設計準則 (Design Aesthetics)

### A. 呼吸感與網格系統 (Whitespace & Rhythm)
- **8px 步進規範**：遵循 `p-4`, `m-2`, `gap-4` 等 8px 網格倍數，建立視覺節奏感。
- **視覺重心**：透過 Padding 的差異化（如 Container 大於 Inner Element），引導使用者焦點。

### B. 視覺層次與深度 (Hierarchy & Depth)
- **資訊對比**：使用字重 (Font Weight) 和色彩透明度來區分重要性。
  - 主標：`text-slate-900 font-semibold`
  - 次標：`text-slate-600 font-medium`
  - 內文：`text-slate-500`
- **現代陰影**：使用分層陰影（如 `shadow-sm` 用於靜態卡片，`shadow-xl` 用於彈窗），營造真實的 Z 軸層次感。

### C. 現代細節與交互工藝 (Modern Touches & Craft)
- **巢狀圓角 (Nested Radius)**：遵循內外比例，當外層容器使用 `rounded-xl` 時，內層元件應對應縮減為 `rounded-lg` 或 `rounded-md`。
- **細膩邊框 (Subtle Borders)**：優先使用帶透明度的邊框（如 `border-slate-200/50`），增加元件在不同背景下的融合感。
- **狀態感知 (State Awareness)**：
  - **交互回饋**：點擊元素必備 `hover:bg-opacity-80` 與微幅 `active:scale-[0.98]`。
  - **效能優化**：過渡效果應限制在特定屬性（如 `transition-colors`），而非全域 `transition-all`。

### D. 無障礙與易用性 (Accessibility & Usability)
- **焦點引導**：所有交互元素必須具備清晰的 `focus-visible` 狀態（例如 `ring-2 ring-offset-2`）。
- **語義化標籤**：優先使用 HTML5 語義標籤 (`<nav>`, `<article>`, `<aside>`)。
- **最小點擊區域**：確保行動裝置上的點擊目標至少具備 44x44px 的熱區。