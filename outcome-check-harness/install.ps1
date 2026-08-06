#Requires -Version 7.0
<#
.SYNOPSIS
  把 outcome-check-harness 的 Stop hook 裝進一個專案，或裝成使用者全域生效。

.DESCRIPTION
  只做「合併」，不覆蓋既有 settings.json 的其他設定。
  裝了之後預設不會攔任何東西——要等該專案自己在
  .claude/outcome-check/rubric.md 寫入驗收條件，這個 Stop hook 才會啟動。
  沒有 rubric 的專案，裝了也是靜默放行，不影響任何行為。

.PARAMETER Scope
  project：只對目前這個專案生效，寫入 .claude/settings.json
  user：對這台機器上所有專案生效，寫入 ~/.claude/settings.json

.PARAMETER Root
  Scope=project 時，目標專案的根目錄。預設為目前工作目錄。

.PARAMETER DryRun
  只印出將執行的動作，不寫入任何檔案。

.EXAMPLE
  pwsh -File install.ps1 -Scope project -Root D:\wsky\Star888Background -DryRun
  pwsh -File install.ps1 -Scope project -Root D:\wsky\Star888Background
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('project', 'user')]
    [string]$Scope,

    [string]$Root = (Get-Location).Path,

    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$hookScriptSource = Join-Path $PSScriptRoot 'hooks\stop-outcome-check.ps1'

if (-not (Test-Path $hookScriptSource)) {
    Write-Host "[FAIL] 找不到 hook 腳本：$hookScriptSource" -ForegroundColor Red
    exit 5
}

if ($Scope -eq 'project') {
    if (-not (Test-Path $Root)) {
        Write-Host "[FAIL] 專案路徑不存在：$Root" -ForegroundColor Red
        exit 5
    }
    $claudeDir     = Join-Path $Root '.claude'
    $settingsPath  = Join-Path $claudeDir 'settings.json'
    $hooksDestDir  = Join-Path $claudeDir 'hooks'
    $rubricDir     = Join-Path $claudeDir 'outcome-check'
} else {
    $claudeDir     = Join-Path $HOME '.claude'
    $settingsPath  = Join-Path $claudeDir 'settings.json'
    $hooksDestDir  = Join-Path $claudeDir 'hooks'
    $rubricDir     = $null   # user 級沒有單一專案的 rubric 目錄，各專案自己開
}

$hookScriptDest = Join-Path $hooksDestDir 'stop-outcome-check.ps1'
$hookCommand    = "pwsh -File `"$hookScriptDest`""

Write-Host "===== outcome-check-harness 安裝 =====" -ForegroundColor Cyan
Write-Host "範圍  ：$Scope"
Write-Host "設定檔：$settingsPath"
Write-Host "Hook  ：$hookScriptDest"
if ($DryRun) { Write-Host "模式  ：DryRun，不會實際寫入" -ForegroundColor Yellow }
Write-Host ""

# ── 讀既有 settings.json（不存在就當空物件）──
$settings = [ordered]@{}
if (Test-Path $settingsPath) {
    try {
        $raw = Get-Content $settingsPath -Raw
        if ($raw.Trim()) {
            $parsed = $raw | ConvertFrom-Json -AsHashtable
            foreach ($key in $parsed.Keys) { $settings[$key] = $parsed[$key] }
        }
    } catch {
        Write-Host "[FAIL] 既有 $settingsPath 不是合法 JSON，手動確認後再跑一次" -ForegroundColor Red
        exit 1
    }
}

if (-not $settings.Contains('hooks')) { $settings['hooks'] = [ordered]@{} }
if (-not $settings['hooks'].Contains('Stop')) { $settings['hooks']['Stop'] = @() }

# ── 檢查是否已經裝過，避免重複加 ──
$alreadyInstalled = $false
foreach ($entry in $settings['hooks']['Stop']) {
    if ($entry.hooks) {
        foreach ($h in $entry.hooks) {
            if ($h.command -and $h.command -like '*stop-outcome-check.ps1*') {
                $alreadyInstalled = $true
            }
        }
    }
}

if ($alreadyInstalled) {
    Write-Host "[SKIP] 這個 settings.json 已經裝過 outcome-check-harness 的 Stop hook，不重複加" -ForegroundColor Yellow
} else {
    $newEntry = [ordered]@{
        hooks = @(
            [ordered]@{
                type    = 'command'
                command = $hookCommand
            }
        )
    }
    $settings['hooks']['Stop'] += $newEntry
    Write-Host "[OK]   Stop hook 條目已準備好加入"
}

# ── 執行寫入 ──
if (-not $DryRun) {
    New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
    New-Item -ItemType Directory -Path $hooksDestDir -Force | Out-Null
    Copy-Item -Path $hookScriptSource -Destination $hookScriptDest -Force
    Write-Host "[OK]   Hook 腳本複製到 $hookScriptDest"

    if (-not $alreadyInstalled) {
        ($settings | ConvertTo-Json -Depth 10) | Set-Content -Path $settingsPath -Encoding UTF8
        Write-Host "[OK]   $settingsPath 已更新"
    }

    if ($rubricDir) {
        New-Item -ItemType Directory -Path $rubricDir -Force | Out-Null
        $rubricTemplate = Join-Path $rubricDir 'rubric.md'
        if (-not (Test-Path $rubricTemplate)) {
            @"
# 驗收條件（outcome-check-harness 讀這份檔案）

刪掉這個範例，換成這次任務真正的驗收條件。每條要能被實際操作驗證，
不能寫「功能正常」這種驗不了的話。

- [ ] 範例：POST /api/orders 帶合法 payload 回傳 200 並帶 order_id
- [ ] 範例：訂單建立後，資料庫 orders 表能查到對應紀錄，status = pending

刪掉這份檔案（或整個 outcome-check/ 資料夾），Stop hook 就不會攔這個專案。
"@ | Set-Content -Path $rubricTemplate -Encoding UTF8
            Write-Host "[OK]   驗收條件範本：$rubricTemplate"
        }

        $gitignorePath = Join-Path $rubricDir '.gitignore'
        if (-not (Test-Path $gitignorePath)) {
            '.attempts' | Set-Content -Path $gitignorePath -Encoding UTF8
        }
    }
}

Write-Host ""
Write-Host "===== 完成 =====" -ForegroundColor Cyan
if ($Scope -eq 'project') {
    Write-Host "下一步：編輯 $rubricDir\rubric.md 寫入這次任務的驗收條件，Stop hook 才會開始攔。"
} else {
    Write-Host "下一步：在任何專案的 <專案根目錄>\.claude\outcome-check\rubric.md 寫入驗收條件即可生效，不用逐專案安裝。"
}
Write-Host ""
Write-Host "⚠️  這支腳本會修改 settings.json（持續性配置）。裝進真正的專案前，" -ForegroundColor Yellow
Write-Host "    先用 -DryRun 看一次動作，並確認該專案的使用者知情同意。" -ForegroundColor Yellow

if ($DryRun) {
    Write-Host ""
    Write-Host "以上為預演結果，未寫入任何檔案。移除 -DryRun 才會實際執行。" -ForegroundColor Yellow
}
