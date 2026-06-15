# 功能需求分析範例報告：會員登入流程優化

> **類型：** 現有功能改善（體驗問題）
> **依據準則：** `feature-analysis-skill` v1.0

---

## 1. 需求背景與痛點

- **目標使用者**：一般會員（終端用戶），每日高頻登入場景
- **解決誰的問題**：會員在登入失敗後不清楚原因（密碼錯？帳號停用？驗證碼過期？），只看到一條通用錯誤訊息「登入失敗」，導致多次重試或直接放棄
- **現有 Workaround**：聯絡客服詢問帳號狀態；無其他替代路徑
- **成功指標**：登入失敗後的再嘗試率（Retry Rate）從目前 38% 提升至 60%；客服接到「帳號登入問題」工單數量降低 30%

---

## 2. 現況與影響範圍評估

**現有行為：** `LoginController@login` 統一回傳 HTTP 422 + 「帳號或密碼錯誤」，無論實際原因為何（密碼錯誤、帳號停用、IP 鎖定、驗證碼失效）。

**已知問題：**
- 用戶無法判斷應該「重試密碼」還是「聯絡客服」，行動路徑不明確
- 帳號停用的用戶反覆嘗試登入，浪費伺服器資源且加重客服負擔

**影響範圍等級：** 🟡 **中度** — 涉及 `LoginController`、`LoginService`、API Response 格式、前端錯誤提示元件，不影響資料庫 Schema

**影響模組：**
- `app/Http/Controllers/LoginController.php`
- `app/Services/Auth/LoginService.php`
- 前端登入頁錯誤訊息區塊

---

## 3. 技術方案比較

| 方案 | 開發成本 | 影響範圍 | 可維護性 | 潛在風險 | 推薦度 |
|------|---------|---------|---------|---------|-------|
| **A：細化錯誤碼，前端對應顯示** | 低（1 天） | 🟡 中度 | 高 | 低 | ⭐⭐⭐ |
| **B：加入引導動作（重設密碼連結）** | 中（2 天） | 🟡 中度 | 高 | 低 | ⭐⭐ |
| **C：完整重構登入流程 + 多因素驗證** | 高（2 週） | 🔴 廣泛 | 中 | 高 | ⭐ |

### 💡 建議選用方案 A，並捆綁部分方案 B 的引導動作
**推薦理由：** 方案 A 後端改動僅需在 `LoginService` 回傳不同 `errorCode`，前端對應枚舉顯示不同訊息。開發成本最低，且直接命中核心痛點（讓用戶知道原因）。附加方案 B 的「忘記密碼」引導連結可同步實作，邊際成本接近零。方案 C 超出本次痛點範疇，標記為 `[IDEA]` 供未來排入。

---

## 4. 實作細節

### 4.1 後端：細化錯誤碼

**目標：** `LoginService` 根據不同失敗原因回傳可識別的 `errorCode`

**做法：**
1. 在 `LoginService@attempt` 中區分失敗類型，回傳對應 errorCode
2. `LoginController` 將 errorCode 包進 422 Response Body

```diff
// LoginService.php
- throw new LoginFailedException('帳號或密碼錯誤');
+ if (!$user) {
+     throw new LoginFailedException('INVALID_CREDENTIALS');
+ }
+ if ($user->status === 'banned') {
+     throw new LoginFailedException('ACCOUNT_SUSPENDED');
+ }
+ if ($this->isIpBlocked(request()->ip())) {
+     throw new LoginFailedException('IP_BLOCKED');
+ }
```

### 4.2 前端：對應錯誤訊息枚舉

```javascript
const ERROR_MESSAGES = {
  INVALID_CREDENTIALS: '帳號或密碼錯誤，請再確認一次',
  ACCOUNT_SUSPENDED:   '此帳號已停用，請聯絡客服處理',
  IP_BLOCKED:          '您的 IP 已被暫時鎖定，請 30 分鐘後再試',
  DEFAULT:             '登入失敗，請稍後再試',
};
```

**預估成本：** 後端 0.5 天 + 前端 0.5 天 = **合計 1 天**

**前置條件：** 確認 `users.status` 欄位的所有可能值已文件化

**驗收標準：**
- [ ] 密碼錯誤 → 顯示「帳號或密碼錯誤」
- [ ] 帳號停用 → 顯示「請聯絡客服」+ 客服連結
- [ ] IP 鎖定 → 顯示「30 分鐘後再試」
- [ ] 系統異常（5xx）→ 顯示通用錯誤，不洩漏技術細節

---

## 5. 優先級

**`[P1]`** — 直接影響用戶核心流程與轉化率，開發成本低，當前迭代排入。

---

## 6. 風險控制

- **相依性風險**：低。僅修改 Response Body 結構，不動 Auth Middleware 與 Session 邏輯
- **資料風險**：無 Schema 異動
- **安全風險**：需確認錯誤訊息區分不會造成「帳號枚舉攻擊（Account Enumeration）」— 建議「帳號不存在」與「密碼錯誤」統一顯示相同訊息 `INVALID_CREDENTIALS`，僅區分帳號停用與 IP 鎖定 `[WARNING]`
- **回滾計畫**：前端 errorCode 若無對應枚舉，預設 fallback 到 `DEFAULT` 訊息，不會白屏崩潰

---

> 💡 **[IDEA]** 長期可考慮加入 TOTP / SMS 二次驗證（方案 C 的部分），但需獨立評估成本與用戶教育成本，不納入本次範疇。
