# API 文件 | {功能名稱}

> 本文件定義此功能涉及的所有 API 路由、Request/Response 格式、錯誤碼與權限規則。  
> 若 API 因專案而異，詳見 `project_diff.md` 與全局 `02_project_diff/Example_api_route_diff.md`。

---

## API 清單

| 端點 | 方法 | 用途 | 權限 | 備註 |
|---|---|---|---|---|
| `/api/example/功能` | GET | 查詢資料 | 登入 | 若涉及客戶資訊需補充角色限制 |
| `/api/example/功能` | POST | 建立資料 | Admin | 待補 |
| `/api/example/功能/{id}` | PUT | 更新資料 | Admin | 待補 |
| `/api/example/功能/{id}` | DELETE | 刪除資料 | Admin | 待補 |

---

## GET `/api/example/功能`

### 說明
查詢此功能的資料清單或詳情。

### Request Query

| 欄位 | 型別 | 必填 | 說明 | 備註 |
|---|---|---|---|---|
| `keyword` | string | 否 | 搜尋關鍵字 | 待補 |
| `status` | string | 否 | 狀態過濾 | 待補 |
| `page` | integer | 否 | 頁碼 | 預設 1 |
| `per_page` | integer | 否 | 每頁筆數 | 預設 20，最大 100 |

### Response

#### 成功 (200)

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "example",
      "status": "enabled",
      "created_at": "2026-01-01T00:00:00Z"
    }
  ],
  "pagination": {
    "total": 100,
    "page": 1,
    "per_page": 20
  },
  "message": "success"
}
```

#### 失敗 (400/403/500)

參見「錯誤碼」章節。

---

## POST `/api/example/功能`

### 說明
建立新的資料。

### Request Body

| 欄位 | 型別 | 必填 | 說明 | 備註 |
|---|---|---|---|---|
| `name` | string | 是 | 名稱 | 最長 255 字 |
| `description` | string | 否 | 說明 | 待補 |
| `status` | string | 否 | 狀態 | 預設 `enabled` |
| `config_json` | object | 否 | 客製設定 | JSON 格式 |

### Response

#### 成功 (201)

```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "example",
    "status": "enabled",
    "created_at": "2026-01-01T00:00:00Z"
  },
  "message": "success"
}
```

---

## PUT `/api/example/功能/{id}`

### 說明
更新指定的資料。

### Request Path

| 欄位 | 型別 | 說明 |
|---|---|---|
| `id` | integer | 資料 ID |

### Request Body

| 欄位 | 型別 | 必填 | 說明 |
|---|---|---|---|
| `name` | string | 否 | 名稱 |
| `description` | string | 否 | 說明 |
| `status` | string | 否 | 狀態 |

### Response

#### 成功 (200)

```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "example",
    "status": "enabled",
    "updated_at": "2026-01-02T00:00:00Z"
  },
  "message": "success"
}
```

---

## DELETE `/api/example/功能/{id}`

### 說明
刪除指定的資料。

### Request Path

| 欄位 | 型別 | 說明 |
|---|---|---|
| `id` | integer | 資料 ID |

### Response

#### 成功 (204)

無 body，僅回傳 HTTP 204 No Content。

---

## 錯誤碼

| 錯誤碼 | HTTP 狀態 | 說明 | 是否寫 Log | 備註 |
|---|---|---|---|---|
| `EXAMPLE_NOT_FOUND` | 404 | 資料不存在 | 否 | 查詢不到指定資料 |
| `EXAMPLE_PERMISSION_DENIED` | 403 | 權限不足 | **是** | 需記錄操作者、操作內容、原因 |
| `EXAMPLE_STATUS_INVALID` | 400 | 狀態不允許操作 | **是** | 需記錄目前狀態與嘗試狀態 |
| `EXAMPLE_VALIDATION_ERROR` | 422 | 資料驗證失敗 | 否 | 返回驗證錯誤詳情 |
| `EXAMPLE_DUPLICATE` | 409 | 資料重複 | 否 | 例如：重複送出請求 |
| `EXAMPLE_INTERNAL_ERROR` | 500 | 系統內部錯誤 | **是** | 需記錄完整 stack trace |

---

## 權限與認證

### 認證方式

| 方式 | 說明 | 備註 |
|---|---|---|
| Bearer Token | JWT Token in `Authorization` header | 預設所有 API 都需要 |
| Session | Cookie-based （若採用） | 待補 |

### 權限規則

| API | 允許角色 | 說明 | 備註 |
|---|---|---|---|
| GET `/api/example/功能` | 登入會員、Admin、客服 | 權限細節待補 | 是否所有角色都能查詢，還是受限於特定條件？ |
| POST `/api/example/功能` | Admin | 待補 | 是否有客服 / 代理可建立？ |
| PUT `/api/example/功能/{id}` | Admin | 待補 | 權限驗證邏輯 |
| DELETE `/api/example/功能/{id}` | Admin | 待補 | 是否有軟刪除？是否需要操作紀錄？ |

---

## 注意事項

- [ ] API 欄位若因專案不同而不同，需同步更新 `project_diff.md`。
- [ ] 涉及外部服務時，需補 request / response log 規則。
- [ ] ⚠️ **高風險**：涉及金流的 API 是否有金額精度、小數位、溢出檢查的說明？
- [ ] ⚠️ **高風險**：涉及權限檢查的 API 是否清楚定義「查看 vs 修改」的差異？
- [ ] ⚠️ **高風險**：若需防止重複送出，是否有 idempotency key 機制？

---

## 待確認項目

| 編號 | 待確認問題 | 影響範圍 | 狀態 |
|---|---|---|---|
| 1 | [待補] | [API / 前端 / 後端] | 待確認 |
| 2 | [待補] | [API / 前端 / 後端] | 待確認 |
