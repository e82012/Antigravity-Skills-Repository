#Requires -Version 7.0
<#
Stop hook：outcome-check 的代碼強制版。
讀 stdin JSON，若當前專案有 rubric，派一個獨立 headless claude -p 裁判驗證，
不通過就用 decision:block 把理由打回主線，逼下一輪重做。

已知限制（讀完再用）：
- 官方文件未記載 hook 內呼叫 claude -p 的遞迴行為，本腳本用環境變數自行防遞迴，
  不是官方保證的機制。
- headless claude -p 是否預設帶完整工具權限（讀檔/跑指令）未經官方文件確認，
  若裁判判定全部落在「無法判定」，先懷疑是不是工具權限不足。
- 沒有真實 Stop 事件跑過這支腳本，行為未經端到端驗證。
#>

$ErrorActionPreference = 'Stop'

# ── 防遞迴：裁判呼叫本身也會觸發一次 Stop，這裡直接放行避免無限迴圈 ──
if ($env:OUTCOME_CHECK_HARNESS_ACTIVE -eq '1') {
    exit 0
}

# ── 讀 stdin JSON ──
$inputJson = [Console]::In.ReadToEnd()
try {
    $payload = $inputJson | ConvertFrom-Json
} catch {
    # 讀不到合法 JSON，不要擋主線，直接放行
    exit 0
}

$cwd = $payload.cwd
if (-not $cwd) { $cwd = (Get-Location).Path }

$rubricPath   = Join-Path $cwd '.claude\outcome-check\rubric.md'
$attemptsPath = Join-Path $cwd '.claude\outcome-check\.attempts'

# ── 沒有 rubric 就不是這個任務的管轄範圍，直接放行 ──
if (-not (Test-Path $rubricPath)) {
    exit 0
}

$rubric = Get-Content $rubricPath -Raw
$lastMessage = $payload.last_assistant_message
if (-not $lastMessage) { $lastMessage = '（沒有拿到 last_assistant_message，裁判請自行從 transcript 判斷）' }

# ── 迭代上限：呼應 global-rules §8，連續 3 輪不過就停 ──
$attempts = 0
if (Test-Path $attemptsPath) {
    $raw = Get-Content $attemptsPath -Raw
    if ($raw -match '^\d+$') { $attempts = [int]$raw }
}

if ($attempts -ge 3) {
    Remove-Item $attemptsPath -ErrorAction SilentlyContinue
    $result = @{
        hookSpecificOutput = @{
            hookEventName    = 'Stop'
            additionalContext = "⚠️ outcome-check-harness：這個 rubric（$rubricPath）已經連續 3 輪裁決不過，依全局準則 §8 停止自動重試。請人工介入：讀 $attemptsPath 的歷史紀錄不到了（已清空計數器），改看這一輪的 last_assistant_message 判斷卡在哪，或直接跟使用者確認 rubric 本身是否寫得不清楚。"
        }
    }
    $result | ConvertTo-Json -Depth 5
    exit 0
}

# ── 組裁判 prompt ──
$judgePrompt = @"
你是一個獨立驗收裁判，不是這個任務的實作者。以下是驗收條件（rubric）與上一輪 assistant 的最終回覆。

嚴禁只讀文字判斷——rubric 裡任何要求「操作」的條件（跑 API、開網頁、查資料庫、跑指令），你必須實際執行，不能用「應該可以」帶過。你有檔案讀取與指令執行能力，用它們。

# 驗收條件
$rubric

# 上一輪最終回覆
$lastMessage

# 輸出格式（只輸出這個 JSON，不要多餘文字）
{"ok": true|false, "reason": "逐條說明每一條的裁決與證據，不通過的要指出具體缺什麼"}
"@

$judgePromptFile = Join-Path $env:TEMP "outcome-check-judge-$(Get-Random).txt"
Set-Content -Path $judgePromptFile -Value $judgePrompt -Encoding UTF8

# ── 呼叫獨立 headless 裁判，設防遞迴旗標 + timeout ──
$env:OUTCOME_CHECK_HARNESS_ACTIVE = '1'
$judgeOutput = $null
$job = Start-Job -ScriptBlock {
    param($promptFile, $cwd)
    # 沒設這個，claude CLI 的 UTF-8 輸出（中文）在 Job 的子行程裡會被讀成亂碼，
    # 導致下游 ConvertFrom-Json 解析失敗——這是實測抓到的，不是預防性寫法。
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    Set-Location $cwd
    $prompt = Get-Content $promptFile -Raw -Encoding UTF8
    & claude -p $prompt --model haiku --output-format json 2>$null
} -ArgumentList $judgePromptFile, $cwd

$finished = Wait-Job $job -Timeout 60
if ($finished) {
    $judgeOutput = Receive-Job $job
}
Remove-Job $job -Force -ErrorAction SilentlyContinue
Remove-Item $judgePromptFile -ErrorAction SilentlyContinue
$env:OUTCOME_CHECK_HARNESS_ACTIVE = $null

if (-not $finished -or -not $judgeOutput) {
    # 裁判逾時或沒有輸出：不要卡死主線，放行但留下警訊
    $result = @{
        hookSpecificOutput = @{
            hookEventName    = 'Stop'
            additionalContext = '⚠️ outcome-check-harness：裁判呼叫逾時或無回應，本輪未驗證，放行。若持續發生，檢查 claude CLI 是否可從 hook 環境呼叫。'
        }
    }
    $result | ConvertTo-Json -Depth 5
    exit 0
}

# ── 解析裁判回覆 ──
try {
    # claude -p --output-format json 的外層是 CLI 自己的包裝，實際判決在 result 欄位裡
    $wrapper = $judgeOutput | ConvertFrom-Json
    $verdictText = $wrapper.result
    if (-not $verdictText) { $verdictText = $judgeOutput }
    # 裁判常把 JSON 包在 ```json ... ``` 裡（實測抓到），剝殼後再解析
    $verdictText = $verdictText -replace '^```(?:json)?\s*', '' -replace '\s*```$', ''
    $verdict = $verdictText.Trim() | ConvertFrom-Json
} catch {
    # 裁判沒回合法 JSON：保守處理為「無法判定」，不阻擋但警告
    $result = @{
        hookSpecificOutput = @{
            hookEventName    = 'Stop'
            additionalContext = "⚠️ outcome-check-harness：裁判回覆不是合法 JSON，本輪未驗證，放行。原始回覆：$judgeOutput"
        }
    }
    $result | ConvertTo-Json -Depth 5
    exit 0
}

if ($verdict.ok -eq $true) {
    Remove-Item $attemptsPath -ErrorAction SilentlyContinue
    exit 0
}

# ── 不通過：計數 +1，打回主線 ──
$attempts += 1
New-Item -ItemType Directory -Path (Split-Path $attemptsPath) -Force | Out-Null
Set-Content -Path $attemptsPath -Value $attempts -Encoding UTF8

$blockResult = @{
    decision = 'block'
    reason   = "outcome-check-harness 裁判判定未通過（第 $attempts/3 輪）：`n`n$($verdict.reason)"
}
$blockResult | ConvertTo-Json -Depth 5
exit 0
