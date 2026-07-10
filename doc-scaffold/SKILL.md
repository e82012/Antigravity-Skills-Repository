---
name: 工程知識庫文件 Scaffold（doc-scaffold）
description: >
  針對 engineering-knowledge-base 的工程功能文件，依照 README.md 規範，
  自動分析功能內容後產出完整的標準文件組（6 份文檔）。
  根據功能複雜度智能判斷是否輸出完整版或簡化版。
  格式與欄位嚴格對齊本 Repo 的範例文件與命名規則。
  當使用者說「幫我建立文件」「產生功能文件」「scaffold 文件」「補文件」或描述了一個功能並希望有對應工程知識庫文件時，觸發此 Skill。
---

# 工程知識庫文件 Scaffold（完整版）

> **Version:** 2.0  
> **Last Updated:** 2026-07-10  
> **適用 Repo：** engineering-knowledge-base  
> **基礎依賴：** 請先閱讀 `README.md` 第 7–9 節，確認文件結構與最小填寫標準

---

## 概述

本 Skill 的目標是：**分析使用者描述的功能或現有程式碼，產出符合 Repo 標準的完整文件組。**

### 產出文件（六份完整組合）

| 檔案 | 產出條件 | 說明 |
|------|---------|------|
| `README.md` | ✅ 總是產出 | 功能總覽、入口、使用角色、影響範圍 |
| `maintenance_notes.md` | ✅ 總是產出 | 維護交接筆記（流程、程式位置、特殊規則、已知問題） |
| `project_diff.md` | ✅ 總是產出 | 各專案/客戶差異（即使目前無差異也需寫明） |
| `api.md` | ⚠️ 條件產出 | API 路由、Request/Response、錯誤碼、權限（涉及 API 則必產） |
| `database.md` | ⚠️ 條件產出 | 資料表、欄位定義、索引、資料異動規則（涉及資料異動則必產） |
| `bdd.md` | ⚠️ 條件產出 | Gherkin 情境、驗收標準（涉及核心流程則建議產出） |

### 簡化版本（三份基礎）

若功能**仍未明確**或**確實不需要 API/DB/BDD**，則僅產出基礎三份：
- `README.md`
- `maintenance_notes.md`
- `project_diff.md`

並在產出說明中標記「因故簡化版本」及建議補齊清單。

---

## 執行流程

### Step 1：分析功能內容與複雜度

依下列優先序理解功能：

1. 使用者直接描述功能用途、所屬模組、適用客戶
2. 若有相關程式碼，從 Controller / Service / Route 推斷功能目的
3. 若有不確定欄位，標記 `待確認` 而非自行猜測

需確認以下基本資訊：

| 資訊 | 用途 |
|------|------|
| 功能名稱 | 文件標題與檔案命名 |
| 所屬模組 | 放置路徑，例如 `member`、`wallet`、`event` |
| 所屬系統 | 例如：管理後台、玩家前台、前後台共用 |
| 適用客戶/專案 | 填入 project_diff.md 差異矩陣 |
| **是否涉及 API？** | 決定是否產出 `api.md` |
| **是否涉及資料異動？** | 決定是否產出 `database.md` |
| **核心流程複雜度** | 決定是否產出 `bdd.md` |

### Step 2：決定產出版本（完整版 vs 簡化版）

判斷依據：

#### ✅ 應產出完整版（六份）
- [ ] 涉及新 API 路由或修改既有 API
- [ ] 涉及新增/修改資料表或重要欄位
- [ ] 涉及金流、權限、限紅、登入、投注等高風險流程
- [ ] 涉及跨專案/客戶差異
- [ ] 涉及排程、Queue、Command 或背景處理

#### ⚠️ 可產出簡化版（三份）
- 功能**仍未明確**，無法產出詳細的 API/DB/BDD
- 功能確實**不涉及 API**（純前端或純後台資料異動）
- 功能確實**不涉及資料異動**（僅查詢或展示）
- 功能確實**不需要 BDD**（簡單邏輯，maintenance_notes 已說明）

### Step 3：決定存放路徑

依功能所屬系統，文件存放在：

```
systems/player-admin-platform/
└── 01_background/01_features/{模組}/{功能名稱}/
    ├── README.md
    ├── maintenance_notes.md
    ├── project_diff.md
    ├── api.md                 # 若涉及 API
    ├── database.md            # 若涉及資料異動
    └── bdd.md                 # 若涉及核心流程
```

檔案命名規則：
- 使用**正式命名**（不加 `Example_` 前綴）
- 功能資料夾名稱：全小寫、底線連接，例如 `bet_limit_setting`
- 若使用者有指定名稱，以使用者提供的為準

### Step 4：根據版本產出文件

#### 完整版本流程（六份）

**第一階段：基礎三份（優先產出）**

使用 `templates/README.md`、`templates/maintenance_notes.md`、`templates/project_diff.md` 填入分析結果。

**第二階段：詳細三份（依需求補齊）**

使用 `templates/api.md`、`templates/database.md`、`templates/bdd.md` 填入。

#### 簡化版本流程（三份）

僅產出基礎三份，並在產出說明中註記「簡化版本」及建議補齊時機。

**通用填寫原則：**
- 能確認的欄位直接填入，不留空
- 無法確認的欄位統一填 `待確認`，**禁止自行猜測後假裝確定**
- 若差異欄目前只有一個客戶，仍需建立差異矩陣，其他客戶欄填 `N/A` 或 `待確認`
- 程式位置（Route / Controller / Service）若無法從描述確定，填 `待補` 並標記「是否已確認：否」

### Step 5：確認基礎三份的完整性

即使產出簡化版，基礎三份也必須完整無缺：

- ✅ `README.md`：功能目的、使用角色、入口、影響範圍都填入
- ✅ `maintenance_notes.md`：流程、程式位置、特殊規則、已知問題都填入
- ✅ `project_diff.md`：必須明確寫出差異或「目前無差異」

### Step 6：檢查文件間的關鍵字段一致性（完整版必檢）

若產出完整版，需驗證以下關鍵字段在六份文件中一致：

| 關鍵字段 | 出現位置 | 驗證規則 |
|---------|---------|---------|
| **API 權限** | `api.md` / `maintenance_notes.md` | 權限定義應相同 |
| **API 錯誤碼** | `api.md` / `maintenance_notes.md` (錯誤處理與Log) | 錯誤碼應一致 |
| **資料表欄位** | `database.md` / `maintenance_notes.md` (相關資料表) | 表名與欄位應一致 |
| **操作角色** | `readme.md` / `maintenance_notes.md` / `api.md` | 三份文件的角色範圍應一致 |
| **專案差異** | `project_diff.md` / `api.md` / `database.md` | 若 api/db 有差異，應在 project_diff 中標記 |

### Step 7：評估是否需要同步更新全局差異文檔

若該功能涉及**專案或客戶差異**，檢查是否需要同步更新：

- `02_project_diff/Example_api_route_diff.md` （若 API 路由不同）
- `02_project_diff/Example_database_diff.md` （若 DB 欄位或表名不同）
- `02_project_diff/Example_feature_enable_matrix.md` （若功能在某專案未啟用）
- `02_project_diff/Example_special_logic_diff.md` （若邏輯有差異）

### Step 8：產出後說明

產出文件後，告知使用者：

1. ✅ 產出版本（完整六份 / 簡化三份）與檔案路徑
2. ⚠️ 哪些欄位標記為「待確認」，需要工程師補充
3. 📋 若產出完整版：提醒跨文件一致性檢查清單
4. 🔗 若涉及差異：建議同步更新的全局文檔列表
5. 📝 若產出簡化版：建議補齊完整版的時機

---

## 格式規範

### 文件格式規範

- 所有標題使用 `#` Markdown 語法
- 所有表格使用標準 Markdown table 格式
- 列表使用 `-` 開頭
- 待確認事項統一使用 `待確認` 文字
- 程式碼路徑使用 inline code 格式：`` `path/to/file` ``
- 高風險項目使用 ⚠️ 或 **粗體** 標記

### 文件特有規範

#### `api.md` 專用規範
- API 權限應與 maintenance_notes 的「使用角色與入口」對應
- 錯誤碼應與 maintenance_notes 的「錯誤處理與 Log」對應
- 若涉及多個專案，應在每個 API 後標記「專案適用」或於 project_diff 中詳述

#### `database.md` 專用規範
- 資料表名應與 maintenance_notes 的「相關資料表」對應
- 若新增資料表，應在 maintenance_notes 的「同功能專案/客戶差異」中標記
- 金額欄位必須使用 `decimal`，不用 `float`

#### `bdd.md` 專用規範
- Scenario 應涵蓋 maintenance_notes 的主要流程
- 應包含成功、失敗、權限、邊界四類情境
- 驗收標準應與 api.md 的錯誤碼與 database.md 的資料異動對應

### 禁止事項

- ❌ 禁止跳過基礎三份中的任何一份
- ❌ 禁止用自己的假設填入「看起來合理但未確認」的程式路徑或 API 設計
- ❌ 禁止省略「待確認」欄位（寧可標記待確認，不可留空）
- ❌ 禁止使用 `Example_` 前綴命名正式文件
- ❌ 禁止在完整版中產出自相矛盾的內容（如 api.md 的權限與 maintenance_notes 不一致）

---

## 配套資源

| 資源 | 路徑 | 用途 |
|------|------|------|
| README 模板 | `templates/README.md` | 功能總覽模板 |
| 維護交接筆記模板 | `templates/maintenance_notes.md` | 維護交接 + 已知問題合併模板 |
| 專案差異模板 | `templates/project_diff.md` | 客戶/專案差異模板 |
| **[新增]** API 模板 | `templates/api.md` | API 路由、Request/Response、錯誤碼 |
| **[新增]** Database 模板 | `templates/database.md` | 資料表、欄位定義、索引、異動規則 |
| **[新增]** BDD 模板 | `templates/bdd.md` | Gherkin 情境、驗收標準 |
| 填寫範例 | `examples/free_spin_card/` | 以「免費旋轉卡」為題的完整填寫示範（六份） |
| **[新增]** 完整指南 | `GUIDE.md` | 各文件的詳細填寫指南與常見陷阱 |
| **[新增]** 交叉引用規範 | `CROSS_REFERENCE.md` | 六份文件間的關鍵字段對應規則 |

---

## 品質檢核（產出前自我檢查）

### 通用檢核（所有版本必檢）

#### README.md
- [ ] 功能目的說明清楚（不是只寫「這是 OOO 功能」）
- [ ] 適用專案表格有填入（至少列出已知客戶，未知填「待確認」）
- [ ] 使用角色有填入
- [ ] 主要入口有填入
- [ ] 影響範圍有勾選或說明

#### maintenance_notes.md
- [ ] 文件基本資訊表格已填（功能名稱、所屬系統、所屬模組）
- [ ] 功能目的說明具體（有「為什麼需要這個功能」的說明）
- [ ] 主要流程有步驟編號
- [ ] 相關程式位置表格已填（未知填「待補」）
- [ ] 相關資料表有填（未知填「待補」）
- [ ] 特殊規則有至少一條（即使只是「目前無已知特殊規則」也要明確寫出）
- [ ] 測試重點有 checkbox 列表

#### project_diff.md
- [ ] 差異矩陣已填（至少有一欄客戶）
- [ ] 若目前無差異，有明確說明「目前無差異」
- [ ] 待確認項目有填（若無，明確寫「目前無待確認事項」）

### 完整版專用檢核

#### api.md（若產出）
- [ ] API 清單表已填（至少一個 API）
- [ ] 每個 API 的 Request 與 Response 已定義
- [ ] 權限規則與 maintenance_notes 的角色對應
- [ ] 錯誤碼已列出，與 maintenance_notes 的錯誤處理對應
- [ ] ⚠️ 高風險項：金流 API 是否有金額精度說明？
- [ ] ⚠️ 高風險項：登入/權限 API 是否有驗證規則？

#### database.md（若產出）
- [ ] 相關資料表已列出，與 maintenance_notes 對應
- [ ] 每個表的欄位、型別、必填已定義
- [ ] 主鍵與索引已列出
- [ ] ⚠️ 高風險項：金額欄位是否使用 `decimal`？
- [ ] ⚠️ 高風險項：時間戳欄位（created_at / updated_at）是否完整？
- [ ] ⚠️ 高風險項：若有軟刪除或狀態欄位，是否有說明？

#### bdd.md（若產出）
- [ ] 至少涵蓋成功、失敗、權限三類 Scenario
- [ ] Scenario 應與 maintenance_notes 的流程對應
- [ ] 驗收標準清單完整（至少 3~4 項）
- [ ] ⚠️ 高風險項：是否涵蓋重複送出防護？
- [ ] ⚠️ 高風險項：是否涵蓋數據回滾規則？

### 完整版交叉驗證

產出完整版前，確認六份文件的一致性：

- [ ] API 的權限 = maintenance_notes 的使用角色
- [ ] API 的錯誤碼 = maintenance_notes 的錯誤處理清單
- [ ] Database 的表名與欄位 = maintenance_notes 的相關資料表
- [ ] BDD 的 Scenario = maintenance_notes 的主要流程 + api.md 的操作
- [ ] 若有專案差異，api.md 與 database.md 中有標記

### 簡化版特殊檢核

若產出簡化版，請註記：

- [ ] 為什麼不產出 api.md？（無 API / 功能未定 / 其他）
- [ ] 為什麼不產出 database.md？（無資料異動 / 功能未定 / 其他）
- [ ] 為什麼不產出 bdd.md？（邏輯簡單 / 功能未定 / 其他）
- [ ] 建議何時補齊完整版？（例如：「規格確認後」或「計畫開發時」）