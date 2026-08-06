#Requires -Version 7.0
<#
.SYNOPSIS
  把 outcome-check-harness 的 Stop hook 裝成使用者全域生效。

.DESCRIPTION
  只裝一次，裝進 ~/.claude/settings.json，對這台機器上所有專案生效，
  完全不碰任何專案目錄——不會在專案裡建立 .claude/settings.json、
  不會建立任何檔案。

  第一版曾經支援「裝進單一專案」（寫進 <專案>/.claude/settings.json），
  已經拿掉：實測發現沒有 .gitignore 排除 .claude/ 的專案，會把這些檔案
  commit 進版控，變成污染。現在 hook 只裝在使用者本機，要不要對某個
  專案啟用，用 set-rubric.ps1 針對該專案寫 rubric 即可，不用重新安裝。

.PARAMETER DryRun
  只印出將執行的動作，不寫入任何檔案。

.EXAMPLE
  pwsh -File install.ps1 -DryRun
  pwsh -File install.ps1
#>

param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$hookScriptSource = Join-Path $PSScriptRoot 'hooks\stop-outcome-check.ps1'

if (-not (Test-Path $hookScriptSource)) {
    Write-Host "[FAIL] 找不到 hook 腳本：$hookScriptSource" -ForegroundColor Red
    exit 5
}

$claudeDir      = Join-Path $HOME '.claude'
$settingsPath   = Join-Path $claudeDir 'settings.json'
$hooksDestDir   = Join-Path $claudeDir 'hooks'
$hookScriptDest = Join-Path $hooksDestDir 'stop-outcome-check.ps1'
$hookCommand    = "pwsh -File `"$hookScriptDest`""

Write-Host "===== outcome-check-harness 安裝（全域） =====" -ForegroundColor Cyan
Write-Host "設定檔：$settingsPath"
Write-Host "Hook  ：$hookScriptDest"
Write-Host "範圍  ：這台機器上所有專案（不會建立任何專案內檔案）"
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
    Write-Host "[SKIP] ~/.claude/settings.json 已經裝過，不重複加" -ForegroundColor Yellow
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

if (-not $DryRun) {
    New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
    New-Item -ItemType Directory -Path $hooksDestDir -Force | Out-Null
    Copy-Item -Path $hookScriptSource -Destination $hookScriptDest -Force
    Write-Host "[OK]   Hook 腳本複製到 $hookScriptDest"

    if (-not $alreadyInstalled) {
        ($settings | ConvertTo-Json -Depth 10) | Set-Content -Path $settingsPath -Encoding UTF8
        Write-Host "[OK]   $settingsPath 已更新"
    }
}

Write-Host ""
Write-Host "===== 完成 =====" -ForegroundColor Cyan
Write-Host "現在對所有專案都是零成本待命（沒有 rubric 就靜默放行，不碰任何專案檔案）。"
Write-Host "要對某個專案啟用，跑："
Write-Host "  pwsh -File set-rubric.ps1 -ProjectRoot <專案路徑> -RubricFile <驗收條件檔案>"

if ($DryRun) {
    Write-Host ""
    Write-Host "以上為預演結果，未寫入任何檔案。移除 -DryRun 才會實際執行。" -ForegroundColor Yellow
}
