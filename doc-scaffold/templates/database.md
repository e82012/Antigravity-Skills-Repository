# Database 文件 | {功能名稱}

> 本文件定義此功能涉及的所有資料表、欄位、索引、約束與資料異動規則。  
> 若資料表因專案而異，詳見 `project_diff.md` 與全局 `02_project_diff/Example_database_diff.md`。

---

## 相關資料表

| 表名 | 用途 | 資料量估計 | 備註 |
|---|---|---|---|
| `example_main` | 功能主資料 | 待補 | 主要查詢與狀態紀錄 |
| `example_log` | 操作紀錄 | 待補 | 紀錄異動前後資料 |
| `member_info` | 會員資料 | - | 若此功能涉及會員需列出 |

---

## `example_main` - 功能主資料表

### 表結構

| 欄位 | 型別 | 必填 | 預設值 | 主鍵 / 外鍵 | 說明 |
|---|---|---|---|---|---|
| `uid` | bigint unsigned | 是 | auto increment | **PK** | 主鍵 |
| `member_info_uid` | bigint unsigned | 否 | null | FK | 會員 UID，有會員才填 |
| `name` | varchar(255) | 是 | null | - | 功能名稱 |
| `status` | varchar(50) | 是 | `enabled` | - | 狀態：enabled / disabled / archived |
| `config_json` | json | 否 | null | - | 客製設定（JSON 格式） |
| `created_by_uid` | bigint unsigned | 否 | null | - | 建立者 UID |
| `updated_by_uid` | bigint unsigned | 否 | null | - | 最後修改者 UID |
| `created_at` | timestamp | 否 | CURRENT_TIMESTAMP | - | 建立時間 |
| `updated_at` | timestamp | 否 | CURRENT_TIMESTAMP ON UPDATE | - | 更新時間 |
| `deleted_at` | timestamp | 否 | null | - | 軟刪除時間（若採用軟刪除） |

### 索引

| 索引名稱 | 欄位 | 索引類型 | 用途 | 備註 |
|---|---|---|---|---|
| `idx_status` | `status` | BTREE | 狀態篩選查詢 | 常用於列表過濾 |
| `idx_member_status` | `member_info_uid`, `status` | BTREE | 會員資料查詢 | 複合索引，查詢會員的特定狀態資料 |
| `idx_created_at` | `created_at` | BTREE | 時間範圍查詢 | 若常需按時間排序 |
| `idx_deleted_at` | `deleted_at` | BTREE | 軟刪除過濾 | 若採用軟刪除，需排除 deleted_at IS NOT NULL |

### 約束

| 約束類型 | 欄位 | 說明 |
|---|---|---|
| UNIQUE | `name` | 功能名稱不重複（若需要） |
| FOREIGN KEY | `member_info_uid` → `member_info(uid)` | 會員必須存在 |
| CHECK | `status` IN ('enabled', 'disabled', 'archived') | 狀態值限制 |

---

## `example_log` - 操作紀錄表

### 表結構

| 欄位 | 型別 | 必填 | 說明 |
|---|---|---|---|
| `uid` | bigint unsigned | 是 | 主鍵 |
| `action` | varchar(50) | 是 | 操作類型：create / update / delete / export 等 |
| `target_uid` | bigint unsigned | 否 | 被操作的資料 UID（可參考 `example_main.uid`） |
| `before_json` | json | 否 | 異動前的資料（供審計） |
| `after_json` | json | 否 | 異動後的資料（供審計） |
| `operator_uid` | bigint unsigned | 否 | 操作者 UID |
| `memo` | text | 否 | 操作備註（例如：修改原因） |
| `ip_address` | varchar(45) | 否 | 操作者 IP |
| `created_at` | timestamp | 否 | 操作時間 |

### 索引

| 索引名稱 | 欄位 | 用途 |
|---|---|---|
| `idx_target_uid` | `target_uid` | 查詢某筆資料的異動紀錄 |
| `idx_operator_created` | `operator_uid`, `created_at` | 查詢某用戶在某時間段的操作 |
| `idx_created_at` | `created_at` | 時間範圍查詢 |

---

## 資料異動規則

### 新增資料 (INSERT)

| 欄位 | 規則 | 備註 |
|---|---|---|
| `uid` | 自動遞增 | 由資料庫生成 |
| `member_info_uid` | 若無會員則填 NULL | 待補 |
| `status` | 預設 `enabled` | 建立時的初始狀態 |
| `created_at` | 自動設為當前時間 | 由資料庫生成 |
| `created_by_uid` | 填入操作者 UID | 來自 API 認證信息 |

### 更新資料 (UPDATE)

| 欄位 | 規則 | 備註 |
|---|---|---|
| `updated_at` | 自動更新為當前時間 | 任何字段異動時 |
| `updated_by_uid` | 填入操作者 UID | 來自 API 認證信息 |
| `config_json` | 僅允許特定角色修改 | 待補角色與限制條件 |
| 其他欄位 | 待補修改規則 | 是否有欄位禁止修改？ |

### 刪除資料 (DELETE)

| 規則 | 說明 |
|---|---|
| 使用軟刪除 | 設置 `deleted_at` 而非物理刪除 |
| 相關紀錄處理 | 若 `example_log` 有關聯，如何處理？ |
| 查詢時過濾 | 所有查詢應排除 `deleted_at IS NOT NULL` |
| 權限要求 | 刪除需 Admin 權限，並寫入操作紀錄 |

---

## 資料一致性與回滾

### 交易 (Transaction) 規則

| 場景 | 交易範圍 | 說明 |
|---|---|---|
| 新增記錄 + 寫操作紀錄 | `INSERT example_main + INSERT example_log` | 兩個操作應在同一交易中，保證原子性 |
| 更新記錄 + 寫操作紀錄 | `UPDATE example_main + INSERT example_log` | 若更新失敗應回滾操作紀錄 |
| 批量更新 | 待補 | 是否需要分批，避免鎖表過久？ |

### 並發控制

| 情境 | 處理方式 | 備註 |
|---|---|---|
| 重複送出相同請求 | 使用 `idempotency_key` 或交易時間戳 | 待補實現細節 |
| 樂觀鎖 | 是否需要版本欄位（如 `version`）| 待補 |
| 悲觀鎖 | 若需要排他鎖，需補說明 | 待補 |

---

## 效能與維護

### 預期資料量與存儲估計

| 場景 | 預期行數 | 存儲大小估計 | 增長速率 | 備註 |
|---|---|---|---|---|
| 日常運營 | 待補 | 待補 | 待補 | 例如：每月增 10K 筆 |
| 峰值 | 待補 | 待補 | - | 高峰期行數估計 |

### 分表建議

| 條件 | 分表方案 | 優先級 |
|---|---|---|
| 若行數超過 1000 萬 | 按時間分表（例如：月分表） | 高 |
| 若查詢延遲超過 100ms | 檢查索引設計 | 中 |
| 待補 | 待補 | - |

### 備份與恢復

| 項目 | 要求 | 備註 |
|---|---|---|
| 備份頻率 | 每日全量 + 每小時增量 | 待補實際策略 |
| 恢復時間 (RTO) | 待補 | 業務可容忍的最長停機時間 |
| 恢復點目標 (RPO) | 待補 | 業務可容忍的最長資料遺失時間 |

---

## 注意事項

- [ ] ⚠️ **高風險**：若涉及金額欄位，是否使用 `decimal`？不能用 `float` 或 `double`！
- [ ] ⚠️ **高風險**：`created_at` / `updated_at` / `deleted_at` 時間戳是否都已定義？
- [ ] ⚠️ **高風險**：若涉及軟刪除，所有查詢是否都有 `WHERE deleted_at IS NULL`？
- [ ] 若資料表因專案不同而異，需在 `project_diff.md` 中標記。
- [ ] 若新增資料表，需同步更新 maintenance_notes.md 的「相關資料表」。
- [ ] 新增欄位時，需評估是否需要 migration 腳本及是否影響既有環境。
- [ ] 修改索引時，需評估對現有查詢性能的影響（可用 EXPLAIN PLAN 驗證）。

---

## 待確認項目

| 編號 | 待確認問題 | 影響範圍 | 狀態 |
|---|---|---|---|
| 1 | [待補] | [表結構 / 索引 / 性能] | 待確認 |
| 2 | [待補] | [資料異動 / 備份 / 恢復] | 待確認 |

---

## 異動紀錄

| 日期 | 調整內容 | 調整人 |
|---|---|---|
| YYYY-MM-DD | 建立文件 | 待補 |
