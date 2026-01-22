---
name: UI-SKILL (UI Craftsman & Aesthetic Skill)
description: 專注於復用 CSS 規範、避免樣式衝突，並注入現代 UI/UX 美學設計靈魂
---

# UI 工匠與美學準則 (UI Craftsman & Aesthetic Skill)

## 1. 樣式復用與一致性 (Consistency)
- **原子化 Class 優先**：強制使用專案現有的 Tailwind/CSS Class。撰寫前必須掃描現有樣式，嚴禁重複造輪子。
- **避免冗餘 CSS**：除非絕對必要，禁止撰寫單一元件專用的獨立 CSS 區塊。
- **組件庫優先**：優先使用專案已有的 UI Kit (如 Shadcn UI, AntD)，而非手刻原始標籤。

---

## 2. 衝突避免與隔離 (Isolation)
- **命名衝突偵測**：新增 Class 前必須全域搜索，確保不與現有樣式覆蓋。
- **技術隔離策略**：若需獨立樣式，優先使用 CSS Modules 或 Tailwind 的 `@layer` 指令。

---

## 3. 美學設計準則 (Design Aesthetics)

### A. 呼吸感與留白 (Whitespace & Rhythm)
- **拒絕擁擠**：UI 元素之間必須有足夠的呼吸空間。遵循 **8px 網格系統**（p-4, m-2 等），確保間距呈倍數增長，建立節奏感。
- **視覺重心**：透過 Padding 的差異化，引導使用者的視線焦點。

### B. 視覺層次 (Visual Hierarchy)
- **對比性**：使用字重 (Font Weight) 和顏色深淺 (Opacity) 來區分資訊重要性。標題用 `text-slate-900`，內文用 `text-slate-600`。
- **陰影與深度**：適度使用 `shadow-sm` 到 `shadow-xl` 來建立 Z 軸層次（如 Modal 應具備明顯陰影，而 Card 應輕微）。

### C. 色彩與材質 (Color & Texture)
- **色盤約束**：嚴禁隨機使用 HEX Code。所有顏色必須對應到專案的 `theme.colors` 或 Tailwind 預設色階。
- **交互回饋**：所有可點擊元素必須包含 `hover:`, `active:`, `focus-visible:` 狀態，且過渡應伴隨 `transition-all duration-200` 以提升質感。

### D. 現代細節 (Modern Touches)
- **圓角美學**：除非特定風格要求，否則應使用現代感較強的圓角