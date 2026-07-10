# 交叉引用規範 - 六份文件間的對應規則

> 本文件定義六份文檔之間的關鍵字段對應關係，確保文檔間信息一致、相互印證，避免矛盾。

---

## 文件間的依賴關係

```
README.md (基礎信息)
  ↓
maintenance_notes.md (流程與規則)
  ├─→ api.md (基於使用角色與流程)
  ├─→ database.md (基於相關資料表)
  └─→ bdd.md (基於主要流程)
     
project_diff.md (各專案差異)
  └─→ api.md 與 database.md 中補充專案標記
```

**填寫順序建議**
1. 先產出 `README.md` 確保基本信息清楚
2. 再產出 `maintenance_notes.md` 定義流程與規則
3. `project_diff.md` 同步整理各專案差異
4. 基於上述三份，產出 `api.md`、`database.md`、`bdd.md`

---

## 關鍵字段對應表

### 1. 「使用角色」跨文件對應

**來源與傳播規則**

| 文件 | 「使用角色」的定義位置 | 應如何對應其他文件 |
|---|---|---|
| **README.md** | 「使用角色」表格 | 這是角色的「標準定義」，其他文件應引用 |
| **maintenance_notes.md** | 「使用角色與入口」表格 | 應與 README 相同；若有細節差異，應補充 |
| **api.md** | 每個 API 的「權限」欄位 | 每個 API 應明確哪些角色可調用 |
| **bdd.md** | 各 Scenario 的 Given 前置條件 | 應驗證各角色的權限限制 |

**一致性檢查**

```
README 的角色 {Admin, 會員, 客服}
  ↓
maintenance_notes 應覆蓋這些角色的權限細節
  ↓
api.md 每個 API 應清楚說明允許哪些角色
  ↓
bdd.md 應有 Scenario 驗證各角色的權限限制
```

**檢查清單**
- [ ] README 列出的角色 ⊇ maintenance_notes 提到的角色
- [ ] api.md 的每個 API 權限都屬於 README 列出的角色
- [ ] bdd.md 至少有一個 Scenario 驗證「無權限角色不能操作」

---

### 2. 「相關資料表」跨文件對應

**來源與傳播規則**

| 文件 | 「相關資料表」的定義位置 | 應如何對應其他文件 |
|---|---|---|
| **maintenance_notes.md** | 「相關資料表」表格 | 這是表的「標準清單」，應列出所有涉及的表 |
| **database.md** | 「相關資料表」章節開始 | 應與 maintenance_notes 的表名一致；詳述結構 |
| **api.md** | Request/Response 的資料結構 | 應映射到 database.md 中定義的欄位 |
| **bdd.md** | 驗收標準中的「資料完整性」 | 應驗證操作後相關表的欄位是否正確更新 |

**一致性檢查**

```
maintenance_notes 的相關表 {example_main, example_log, member_info}
  ↓
database.md 應完整定義這些表的結構
  ↓
api.md Response 中的欄位應來自 database.md 定義的欄位
  ↓
bdd.md 驗收標準應驗證資料表的欄位異動
```

**檢查清單**
- [ ] maintenance_notes 列出的每個表都在 database.md 中有完整定義
- [ ] api.md 的 Response 欄位都能在 database.md 中找到對應
- [ ] bdd.md 的驗收標準驗證了主要表的欄位更新

---

### 3. 「API 權限」跨文件對應

**來源與傳播規則**

| 文件 | API 權限的定義位置 | 應如何對應其他文件 |
|---|---|---|
| **api.md** | 每個 API 的「權限」欄位 | 這是「單一來源」，定義每個 API 誰能調用 |
| **maintenance_notes.md** | 「使用角色與入口」表格 | 應該與 api.md 一致，可補充入口細節 |
| **bdd.md** | 「權限不足時不可操作」Scenario | 應驗證無權限角色確實被拒絕 |

**一致性檢查**

```
api.md 定義：
  POST /api/example → 權限 = Admin

maintenance_notes.md 應說明：
  Admin 可建立，其他角色不能 → 與 api.md 對應

bdd.md 應驗證：
  Scenario: 權限不足時不可操作
    Given 非 Admin 角色
    When 嘗試 POST /api/example
    Then 系統應拒絕並回傳 PERMISSION_DENIED
```

**檢查清單**
- [ ] api.md 定義的每個 API 權限都在 maintenance_notes 中有說明
- [ ] bdd.md 至少有一個 Scenario 驗證高風險 API 的權限檢查
- [ ] 若 api.md 的權限與 maintenance_notes 不符，應在 project_diff 中標記原因

---

### 4. 「API 錯誤碼」跨文件對應

**來源與傳播規則**

| 文件 | 錯誤碼的定義位置 | 應如何對應其他文件 |
|---|---|---|
| **api.md** | 「錯誤碼」表格 | 這是「單一來源」，定義所有可能的錯誤碼與含義 |
| **maintenance_notes.md** | 「錯誤處理與 Log」表格 | 應列出哪些錯誤需要寫日誌、如何處理 |
| **bdd.md** | 各失敗 Scenario | 應驗證系統回傳的錯誤碼符合 api.md 定義 |

**一致性檢查**

```
api.md 定義的錯誤碼：
  - PERMISSION_DENIED (403)
  - VALIDATION_ERROR (422)
  - RESOURCE_NOT_FOUND (404)

maintenance_notes.md 應說明：
  - PERMISSION_DENIED 需寫日誌（安全審計）
  - VALIDATION_ERROR 不需寫日誌
  - RESOURCE_NOT_FOUND 不需寫日誌

bdd.md 應驗證：
  Scenario: 權限不足時不可操作
    Then 系統應回傳 PERMISSION_DENIED 錯誤碼
```

**檢查清單**
- [ ] maintenance_notes 的「錯誤處理與 Log」中提到的錯誤碼都在 api.md 中定義
- [ ] bdd.md 的各失敗 Scenario 都驗證了對應的錯誤碼
- [ ] api.md 中每個標記「是否寫 Log=是」的錯誤碼都在 maintenance_notes 中有 Log 規則

---

### 5. 「特殊規則」與「流程」跨文件對應

**來源與傳播規則**

| 文件 | 特殊規則的定義位置 | 應如何對應其他文件 |
|---|---|---|
| **maintenance_notes.md** | 「特殊規則」表格 + 「主要流程」 | 這是「規則的標準定義」 |
| **api.md** | 說明欄、Request 驗證規則、錯誤碼 | 應映射到特殊規則 |
| **database.md** | 約束、觸發器、異動規則 | 應映射到特殊規則 |
| **bdd.md** | Scenario 的 Given 與 Then | 應驗證特殊規則的執行 |

**一致性檢查**

```
maintenance_notes 定義特殊規則：
  「會員個別設定優先於代理預設設定」

api.md 應說明：
  GET /api/example 的 Response 應優先返回會員設定，若無則返回代理設定

database.md 應定義：
  example_main 包含 member_config 與 agent_config 欄位；
  查詢邏輯應優先讀 member_config

bdd.md 應驗證：
  Scenario: 會員個別設定優先於代理設定
    Given 會員既有個別設定，也被代理套用預設設定
    When 查詢會員設定
    Then 系統應回傳會員個別設定（非代理預設）
```

**檢查清單**
- [ ] maintenance_notes 的每條特殊規則都被至少一份其他文件所應用或驗證
- [ ] bdd.md 至少有一個 Scenario 驗證主要的特殊規則
- [ ] database.md 的表結構與異動規則支援 maintenance_notes 定義的規則

---

### 6. 「主要流程」與 「Scenario」跨文件對應

**來源與傳播規則**

| 文件 | 流程的定義位置 | 應如何對應其他文件 |
|---|---|---|
| **maintenance_notes.md** | 「主要流程」（步驟編號） | 這是「流程的標準定義」 |
| **bdd.md** | 各個 Scenario 的 Given/When/Then | 應涵蓋 maintenance_notes 的流程 |

**一致性檢查**

```
maintenance_notes 的主要流程（5 步）：
  1. 會員登入遊戲
  2. 系統檢查是否有未領取的旋轉卡
  3. 若有，自動派發
  4. 會員選擇使用
  5. 系統扣除並記錄結果

bdd.md 應有 Scenario 涵蓋：
  ✅ Scenario: 成功自動派發旋轉卡（步驟 1~3）
  ✅ Scenario: 成功使用旋轉卡（步驟 4~5）
  ✅ Scenario: 無旋轉卡時的流程（步驟 2 的分支）
  ✅ Scenario: 重複送出的防護（步驟 5 的邊界）
```

**檢查清單**
- [ ] maintenance_notes 的主要流程至少有一個 Scenario 驗證
- [ ] bdd.md 的每個 Scenario 都能對應到 maintenance_notes 的某個流程或規則
- [ ] maintenance_notes 的流程步驟順序與 bdd.md 的 Scenario 步驟一致

---

## 專案差異的跨文件標記

若存在專案或客戶差異，應在相關文件中標記並互相引用。

### 差異標記規則

#### 在 README.md 中標記
```md
| 專案 | 是否啟用 | 備註 |
|---|---|---|
| 專案 A | 是 | 公版流程 |
| 專案 B | 是 | 有客製差異，詳見 `project_diff.md` ⚠️ |
```

#### 在 api.md 中標記
```md
| 端點 | 方法 | 用途 | 備註 |
|---|---|---|---|
| `/api/v1/example` | POST | 建立 | ⚠️ 專案 B 此端點不同，見 `project_diff.md` |
```

#### 在 database.md 中標記
```md
| 表名 | 用途 | 備註 |
|---|---|---|
| `example_main` | 主資料 | ⚠️ 專案 B 多一欄 `example_type`，見 `project_diff.md` |
```

#### 在 project_diff.md 中詳述
```md
| 比較項目 | 專案 A | 專案 B | 備註 |
|---|---|---|---|
| API 路由 | 相同 | `/api/v2/example` | 專案 B 使用舊版端點 |
| DB 欄位 | 標準欄位 | 多一欄 `example_type` | 需在 migration 中處理 |
```

### 檢查清單
- [ ] 若 api.md 有專案差異，project_diff.md 中是否有明確標記？
- [ ] 若 database.md 有專案差異，project_diff.md 中是否有明確標記？
- [ ] 若 project_diff.md 提到某個 API/DB 差異，相應的 api.md/database.md 中是否有反向引用？

---

## 高風險功能的跨文件對應

若功能涉及金流、權限、排程等高風險領域，應強化跨文件的一致性檢查。

### 金流功能特別檢查

| 檢查項 | README | maintenance_notes | api.md | database.md | bdd.md |
|---|---|---|---|---|---|
| 金額欄位說明 | ✅ 提及 | ✅ 說明使用場景 | ✅ Request/Response 欄位 | ✅ 用 `decimal` 定義，精度說明 | ✅ 驗證精度與溢出 |
| 權限控制 | ✅ 誰可操作 | ✅ 權限規則詳述 | ✅ 每 API 定義 | ✅ 操作者 UID 記錄 | ✅ 驗證權限拒絕 |
| 日誌記錄 | ✅ 提及 | ✅ Log 規則詳述 | ✅ 標記高風險操作 | ✅ 日誌表結構 | ✅ 驗證 Log 寫入 |
| 回滾機制 | ✅ 說明異常處理 | ✅ 交易規則 | ✅ 錯誤碼 | ✅ 交易定義 | ✅ 驗證回滾 |

---

## 檢查流程（產出完整版前執行）

### Step 1：基礎一致性檢查
```
□ README 的角色 vs maintenance_notes 的角色 → 應相同或 maintenance_notes 更詳細
□ README 的相關表 vs database.md 的表 → 應相同
□ maintenance_notes 的流程 vs bdd.md 的 Scenario → 應涵蓋所有流程
```

### Step 2：API 一致性檢查
```
□ api.md 的每個 API → maintenance_notes 應有對應的「入口」說明
□ api.md 的權限 → README 與 maintenance_notes 應一致
□ api.md 的錯誤碼 → maintenance_notes 應說明哪些需寫 Log
□ api.md 的 Response 欄位 → database.md 應有對應的表欄位定義
```

### Step 3：資料一致性檢查
```
□ database.md 的表名 → maintenance_notes 應列出
□ database.md 的主鍵/外鍵 → 應正確關聯
□ database.md 的異動規則 → bdd.md 的 Scenario 應驗證
```

### Step 4：Scenario 一致性檢查
```
□ bdd.md 的每個 Scenario → 應對應 maintenance_notes 的某個流程或規則
□ bdd.md 的失敗情境 → api.md 的錯誤碼應被測試
□ bdd.md 的權限情境 → api.md 的權限定義應被驗證
```

### Step 5：專案差異檢查
```
□ project_diff.md 提到的差異 → api.md/database.md 中應有對應標記
□ api.md/database.md 中的差異標記 → project_diff.md 應有詳述
```

---

## 常見不一致案例與解決方案

### 案例 1：權限不一致
❌ **問題**
```
README.md：「Admin 與客服都可操作」
api.md：「POST /api/example 權限 = Admin」
```

✅ **解決方案**
```
方案 A（推薦）：修改 api.md，補充客服權限
  POST /api/example 權限 = Admin + 客服

方案 B：修改 README.md，澄清客服不能全部操作
  README：「Admin 可全部操作；客服只能查詢」
```

### 案例 2：表名不一致
❌ **問題**
```
maintenance_notes.md：「相關資料表：user_setting」
database.md：「表名：user_config」
```

✅ **解決方案**
```
方案 A（推薦）：統一表名
  maintenance_notes → user_config
  database.md → user_config

方案 B：補充說明
  maintenance_notes 註記「user_setting 即 user_config」
```

### 案例 3：流程步驟不對應
❌ **問題**
```
maintenance_notes：5 個流程步驟
bdd.md：只有 2 個 Scenario 驗證
```

✅ **解決方案**
```
補充 bdd.md：
  ✅ Scenario 1：步驟 1-2（查詢階段）
  ✅ Scenario 2：步驟 3-4（操作階段）
  ✅ Scenario 3：步驟 5（結果驗證）
  ✅ Scenario 4：異常情境（邊界測試）
```

---

## 自動化檢查建議

若團隊規模較大，建議編寫腳本檢查以下項目：

### 檢查清單（可自動化）

| 檢查項 | 實現方式 |
|---|---|
| 角色一致性 | 正則搜尋 README 與 api.md 中的角色名稱，應 100% 對應 |
| 表名一致性 | 搜尋 maintenance_notes 與 database.md 的表名，應相同 |
| API 覆蓋性 | 驗證 bdd.md 的 Scenario 是否覆蓋 api.md 的所有重要 API |
| 錯誤碼覆蓋性 | 驗證 bdd.md 的 Scenario 是否測試 api.md 列出的所有主要錯誤碼 |
| 流程對應性 | 驗證 bdd.md 是否涵蓋 maintenance_notes 定義的所有流程步驟 |

---

## 總結檢查清單

產出六份完整文檔後，務必檢查：

- [ ] **角色一致** — README/maintenance_notes/api.md 的角色完全相同
- [ ] **表名一致** — maintenance_notes/database.md 的表名相同
- [ ] **API 完整** — api.md 的所有 API 都在 maintenance_notes 中有說明
- [ ] **權限清楚** — api.md 的每個 API 權限都在 bdd.md 中被測試
- [ ] **錯誤完整** — api.md 的錯誤碼都在 maintenance_notes 的 Log 規則中有說明
- [ ] **流程對應** — bdd.md 的 Scenario 都對應 maintenance_notes 的流程或規則
- [ ] **專案標記** — project_diff.md 的差異都在 api.md/database.md 中有對應標記
- [ ] **高風險項** — 金流/權限/日誌的三份文檔都有詳細說明與驗證
