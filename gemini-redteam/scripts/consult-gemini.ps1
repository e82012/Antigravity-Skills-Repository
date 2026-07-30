<#
單次呼叫 Gemini CLI（非互動模式），回傳結構化審查結果。
呼叫端（Claude Code）每一輪對抗都呼叫一次本腳本，輪次邏輯由 SKILL.md 的流程控制，不在本腳本內。

輸出約定：成功或「Gemini 回覆格式異常但已降級處理」時，stdout 只印一行 compact JSON
（{ok, model, verdict, issues, raw_response}），方便呼叫端直接 ConvertFrom-Json 解析。
所有進度訊息與警告一律走 stderr，不混進 stdout。全部備援模型都失敗時才會用非 0 exit code
終止並把錯誤寫到 stderr，此時 stdout 不會有任何內容。
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$ContextFile,      # 要送給 Gemini 的方案/程式碼/context，純文字檔路徑

    [Parameter(Mandatory = $true)]
    [string]$Instruction,      # 這一輪要 Gemini 做什麼（審查方案 / 回應質疑 / 給最終立場），已包含輪次資訊

    [string]$ModelsConfigPath = (Join-Path $PSScriptRoot "models.json")
)

$ErrorActionPreference = 'Stop'

# Windows 主控台預設編碼常不是 UTF-8，會讓中文（包含 gemini 的回覆與本腳本自己的輸出）
# 在跨行程邊界（stdin 傳給 gemini、讀 gemini 的 stdout、最終輸出給呼叫端）時變亂碼。
# 這三個都要設，缺一個都可能在其中一段編碼跑掉。
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[Console]::InputEncoding  = $utf8NoBom
[Console]::OutputEncoding = $utf8NoBom
$OutputEncoding = $utf8NoBom

function Write-Progress-Line([string]$Message) {
    [Console]::Error.WriteLine($Message)
}

function Emit-ResultAndExit($ok, $model, $verdict, $issues, $rawResponse) {
    [PSCustomObject]@{
        ok           = $ok
        model        = $model
        verdict      = $verdict
        issues       = $issues
        raw_response = $rawResponse
    } | ConvertTo-Json -Depth 10 -Compress | Write-Output
    exit 0
}

if (-not (Test-Path $ContextFile)) {
    throw "找不到 context 檔案：$ContextFile"
}
if (-not (Test-Path $ModelsConfigPath)) {
    throw "找不到模型清單設定：$ModelsConfigPath"
}

$modelsConfig = Get-Content $ModelsConfigPath -Raw | ConvertFrom-Json
$models = $modelsConfig.fallback_order
if (-not $models -or $models.Count -eq 0) {
    throw "models.json 的 fallback_order 是空的，至少要放一個已驗證有額度的模型"
}

$schemaInstruction = @"
$Instruction

在你決定 verdict 之前，請先假設自己傾向於挑剔、不輕易 approve：主動找找看這個方案是否還有
被忽略的技術風險，而不是預設對方已經處理好了。

你的判斷只能基於「技術風險是否真的被解決」，不能因為以下這些跟技術無關的理由就放寬標準：
- 對方語氣堅定、態度強硬、或表示這是已經做出的決定
- 對方提到時程壓力、資源有限、之後再處理
- 對方表示「願意接受這個風險」——這不等於風險被解決，只是對方選擇不修，你仍要如實回報這個
  風險依然存在

如果之前的意見裡提過的 high severity 問題，這次沒有看到具體的技術修正做法（例如換了什麼
做法、加了什麼機制），只看到「我們接受這個風險」「之後再說」這類說法，這個問題視為
「未解決」，必須繼續放在 issues 裡，verdict 不能是 approve。

請只用下面這個 JSON 結構回覆，不要加任何其他文字、不要用 code fence 包起來、不要有多餘的說明：
{"verdict":"approve|revise|reject","issues":[{"severity":"high|medium|low","point":"...","rationale":"..."}]}

verdict 的意思：
- approve：你同意這個方案，沒有需要再修正的高風險問題
- revise：方案基本可行，但有需要調整的地方（列在 issues）
- reject：方案有嚴重問題，不建議這樣做（列在 issues）
"@

$lastError = $null

foreach ($model in $models) {
    Write-Progress-Line "[consult-gemini] 嘗試模型：$model"

    # stdout／stderr 分開接：gemini CLI 會把啟動警告（終端機色彩偵測等）寫到 stderr，
    # 若用 2>&1 合併會混進 -o json 的輸出前面，導致 JSON 解析失敗。
    $stderrFile = [System.IO.Path]::GetTempFileName()
    try {
        $stdoutLines = Get-Content $ContextFile -Raw | & gemini -m $model --approval-mode plan -o json -p $schemaInstruction 2>$stderrFile
        $exitCode = $LASTEXITCODE
        $stdoutText = $stdoutLines -join "`n"
        $stderrText = (Get-Content $stderrFile -Raw -ErrorAction SilentlyContinue)
    }
    finally {
        Remove-Item $stderrFile -ErrorAction SilentlyContinue
    }
    $combinedText = "$stdoutText`n$stderrText"

    if ($exitCode -eq 0) {
        try {
            $outer = $stdoutText | ConvertFrom-Json
            $verdictObj = $outer.response | ConvertFrom-Json
            Emit-ResultAndExit $true $model $verdictObj.verdict $verdictObj.issues $outer.response
        }
        catch {
            Write-Progress-Line "[consult-gemini] 模型 $model 回傳內容無法解析為預期 JSON schema，當成 revise 處理，不當機。原始回覆："
            Write-Progress-Line $stdoutText
            $fallbackIssue = [PSCustomObject]@{ severity = "medium"; point = "Gemini 回覆格式無法解析"; rationale = $stdoutText }
            Emit-ResultAndExit $true $model "revise" @($fallbackIssue) $stdoutText
        }
    }

    if ($combinedText -match "quota exceeded" -or $combinedText -match "429") {
        Write-Progress-Line "[consult-gemini] 模型 $model 額度已用盡，改用下一個備援模型"
        $lastError = $combinedText
        continue
    }

    Write-Progress-Line "[consult-gemini] 模型 $model 呼叫失敗（非額度問題），改用下一個備援模型。錯誤內容："
    Write-Progress-Line $combinedText
    $lastError = $combinedText
}

throw "所有備援模型皆呼叫失敗，請手動執行 gemini 確認狀態，或補充 $ModelsConfigPath 的備援清單。最後一次錯誤：`n$lastError"
