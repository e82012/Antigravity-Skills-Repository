#Requires -Version 7.0
<#
.SYNOPSIS
  對某個專案設定／查看／清除 outcome-check-harness 的驗收條件。

.DESCRIPTION
  驗收條件寫在使用者本機的 ~/.claude/outcome-check-state/<專案 key>/rubric.md，
  不碰專案目錄本身。這裡的路徑轉換規則必須跟 hooks/stop-outcome-check.ps1
  裡的完全一致，否則 hook 讀不到寫在這裡的東西。

.PARAMETER ProjectRoot
  目標專案的根目錄（絕對路徑，跟 Claude Code 啟動時的 cwd 一致才配得對）。

.PARAMETER RubricFile
  現成的驗收條件檔案路徑，內容會被複製過去。跟 -RubricText 擇一。

.PARAMETER RubricText
  直接傳入驗收條件文字。跟 -RubricFile 擇一。

.PARAMETER Show
  印出這個專案目前的驗收條件與已嘗試輪數，不寫入任何東西。

.PARAMETER Clear
  清掉這個專案的驗收條件（等於停用驗收，之後 Stop hook 會靜默放行）。

.EXAMPLE
  pwsh -File set-rubric.ps1 -ProjectRoot D:\wsky\Star888Background -RubricFile .\my-rubric.md
  pwsh -File set-rubric.ps1 -ProjectRoot D:\wsky\Star888Background -Show
  pwsh -File set-rubric.ps1 -ProjectRoot D:\wsky\Star888Background -Clear
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot,

    [string]$RubricFile,
    [string]$RubricText,

    [switch]$Show,
    [switch]$Clear
)

$ErrorActionPreference = 'Stop'

# ── 專案路徑 → 狀態目錄 key，必須跟 hook 腳本裡的算法完全一致 ──
function Get-StateDir {
    param([string]$ProjectPath)
    $resolved = (Resolve-Path $ProjectPath -ErrorAction Stop).Path
    $safeName = ($resolved -replace '[:\\/]', '-').Trim('-')
    $hashBytes = [System.Security.Cryptography.MD5]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($resolved))
    $shortHash = ([System.BitConverter]::ToString($hashBytes) -replace '-', '').Substring(0, 8).ToLower()
    return Join-Path $HOME ".claude\outcome-check-state\$safeName-$shortHash"
}

if (-not (Test-Path $ProjectRoot)) {
    Write-Host "[FAIL] 專案路徑不存在：$ProjectRoot" -ForegroundColor Red
    exit 5
}

$stateDir     = Get-StateDir -ProjectPath $ProjectRoot
$rubricPath   = Join-Path $stateDir 'rubric.md'
$attemptsPath = Join-Path $stateDir '.attempts'

if ($Show) {
    Write-Host "狀態目錄：$stateDir"
    if (Test-Path $rubricPath) {
        Write-Host "--- rubric.md ---"
        Get-Content $rubricPath -Raw
        $attempts = 0
        if (Test-Path $attemptsPath) { $attempts = Get-Content $attemptsPath -Raw }
        Write-Host "--- 已嘗試輪數：$attempts/3 ---"
    } else {
        Write-Host "這個專案目前沒有設定驗收條件（Stop hook 會靜默放行）。"
    }
    exit 0
}

if ($Clear) {
    if (Test-Path $stateDir) {
        Remove-Item $stateDir -Recurse -Force
        Write-Host "[OK] 已清除 $ProjectRoot 的驗收條件，Stop hook 之後會靜默放行。"
    } else {
        Write-Host "[SKIP] 這個專案本來就沒有設定，沒東西可清。"
    }
    exit 0
}

if (-not $RubricFile -and -not $RubricText) {
    Write-Host "[FAIL] 要嘛給 -RubricFile，要嘛給 -RubricText，兩個都沒給就不知道要寫什麼" -ForegroundColor Red
    exit 1
}

if ($RubricFile -and -not (Test-Path $RubricFile)) {
    Write-Host "[FAIL] 找不到 -RubricFile：$RubricFile" -ForegroundColor Red
    exit 5
}

$content = if ($RubricFile) { Get-Content $RubricFile -Raw } else { $RubricText }

New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
Set-Content -Path $rubricPath -Value $content -Encoding UTF8

Write-Host "[OK] 驗收條件已寫入 $rubricPath"
Write-Host "這個專案的下一輪 Stop 就會開始被裁判驗收。"
