# RESTful API 規格書 (樣板)

> 本樣板為 `restful-api-spec-writer` 技能的**強制輸出格式**。每一支 API 都必須逐字逐節套用以下結構，標題層級、欄位名稱、順序不可更動或刪減。若某欄位不適用，仍須保留標題並填寫「無」，不得整段刪除。

---

## 0. 需求總覽（多支 API 時使用）

> 當一個需求拆解為多支 API 時，先在此區塊用 2-4 句話總結「資源模型」與「拆出幾支 API、各自用途」，接著依 CRUD 慣例順序（Create → Read(List) → Read(Detail) → Update → Delete）逐一輸出下方模板，每支 API 之間以 `---` 分隔。若僅有單一 API，可省略本區塊。

[資源模型與 API 拆解總覽說明]

---

## API 名稱：[簡短中文功能名稱]（English Name）

### 1. 功能說明
[1-3 句話描述這支 API 做什麼、給誰用、在什麼情境下被呼叫]

### 2. URL Path
`{METHOD} /v1/resource-path`

### 3. HTTP Method
[GET / POST / PUT / PATCH / DELETE]（擇一，並用一句話說明為何選用此 Method）

### 4. Params

#### 4.1 Path Parameters
| 參數名稱 | 型別 | 必填 | 說明 |
|---|---|---|---|
| 範例：userId | string | 是 | 使用者唯一識別碼 |

（若無 Path Parameter，填寫：「無」）

#### 4.2 Query Parameters
| 參數名稱 | 型別 | 必填 | 預設值 | 說明 |
|---|---|---|---|---|
| 範例：page | integer | 否 | 1 | 分頁頁碼 |

（若無 Query Parameter，填寫：「無」）

### 5. Request Body
[若無 Request Body（如 GET/DELETE），填寫：「無」]

| 欄位名稱 | 型別 | 必填 | 說明 |
|---|---|---|---|
| 範例：title | string | 是 | 訂單標題，長度 1-100 字 |

**JSON 範例：**
```json
{
  "title": "範例標題"
}
```

### 6. Response

#### 6.1 成功回應
**HTTP 狀態碼：** `200 OK`（依實際情境填寫正確狀態碼）

**說明：** [描述成功時回傳什麼]

**JSON 範例：**
```json
{
  "id": "string",
  "title": "string",
  "createdAt": "2026-06-30T12:00:00Z"
}
```

#### 6.2 錯誤回應
列出此 API 可能發生的**所有**錯誤情境，至少涵蓋：參數驗證錯誤、身份驗證/權限錯誤（若適用）、資源不存在（若適用）。至少列出 2 種以上錯誤（除非邏輯上真的只可能有一種，仍須說明原因）。

**HTTP 狀態碼：** `400 Bad Request`

**說明：** [錯誤情境描述]

**JSON 範例：**
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "欄位 title 不可為空"
  }
}
```

（針對每個錯誤狀態碼重複上述「狀態碼／說明／JSON 範例」三段格式）

### 7. 備註與假設（如有）
[列出產出此規格時所做的任何合理假設，例如：「假設此 API 需要登入驗證，故於 Header 需帶 Authorization: Bearer {token}」]

---

## 附錄：共通規範（多支 API 時使用）

> 若多支 API 有共通的錯誤碼規範或身份驗證機制，統一在此說明，避免每支 API 重複贅述。個別 API 的「6.2 錯誤回應」仍須列出該 API 實際會用到的錯誤碼。

- **共通身份驗證**：[例如：所有需登入的 API 皆需於 Header 帶 `Authorization: Bearer {token}`]
- **共通錯誤碼**：[列出跨 API 共用的 error code 對照表]
