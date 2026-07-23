<#
.SYNOPSIS
    將 AntiGravity-Skill 倉庫同步到各 AI 代理的設定目錄。

.DESCRIPTION
    以本倉庫為單一真實來源，把「全局準則」與「技能」覆蓋到 Claude Code、
    Gemini / Antigravity、Codex 的對應位置。所有目標端都是產生物，
    改規則一律改本倉庫再跑同步。

.EXAMPLE
    pwsh -File tools\sync-skills.ps1
    顯示選單，人工選擇要同步什麼

.EXAMPLE
    pwsh -File tools\sync-skills.ps1 -Mode all -Target claude -DryRun
    預演：把全局準則與所有技能同步到 Claude Code，只印不動

.NOTES
    退出碼見 tools\README.md
#>

[CmdletBinding()]
param(
    # rules = 只同步全局準則；skills = 只同步技能；all = 兩者
    [ValidateSet('rules', 'skills', 'all')]
    [string]$Mode,

    # 要同步到哪個代理
    [ValidateSet('claude', 'gemini', 'codex', 'all')]
    [string]$Target = 'all',

    # 來源倉庫根目錄，預設為本腳本的上一層
    [string]$Root,

    # 只印出將執行的動作，不實際寫入
    [switch]$DryRun,

    # 允許同步標記為「路徑未驗證」的目標
    [switch]$AllowUnverified
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# 退出碼（PowerShell 裸 throw 在 pwsh -File 下會回 exit 0，一律用顯式 exit）
# ---------------------------------------------------------------------------
$EXIT_OK              = 0
$EXIT_ERROR           = 1
$EXIT_BAD_ARGS        = 2
$EXIT_TARGET_MISSING  = 3
$EXIT_PATH_MANGLED    = 4
$EXIT_SOURCE_MISSING  = 5
$EXIT_BACKUP_FAILED   = 6

function Write-Step { param([string]$Text) Write-Host "  $Text" }
function Write-Ok   { param([string]$Text) Write-Host "  [OK]   $Text" -ForegroundColor Green }
function Write-Skip { param([string]$Text) Write-Host "  [SKIP] $Text" -ForegroundColor DarkGray }
function Write-Warn { param([string]$Text) Write-Host "  [WARN] $Text" -ForegroundColor Yellow }

function Fail {
    param([int]$Code, [string]$Message)
    Write-Host ""
    Write-Host "[FAIL] $Message" -ForegroundColor Red
    Write-Host "       退出碼 $Code（意義見 tools\README.md）" -ForegroundColor Red
    exit $Code
}

# 從 Bash 等 shell 呼叫時，未加引號的反斜線會被吃掉（d:\proj -> d:proj），
# 導致參數靜默綁錯。含磁碟機代號卻沒有任何分隔符 = 被吃掉了。
function Test-PathMangled {
    param([string]$PathValue)
    if ([string]::IsNullOrWhiteSpace($PathValue)) { return $false }
    return ($PathValue -match '^[A-Za-z]:[^\\/]' )
}

# ---------------------------------------------------------------------------
# 目標定義
#   Verified = $false 代表路徑未在本機實證過，預設跳過，需 -AllowUnverified
# ---------------------------------------------------------------------------
$UserHome = $env:USERPROFILE
if ([string]::IsNullOrWhiteSpace($UserHome)) { $UserHome = $HOME }

$TargetMap = [ordered]@{
    claude = @{
        Name          = 'Claude Code'
        RulesFile     = Join-Path $UserHome '.claude\CLAUDE.md'
        SkillsDir     = Join-Path $UserHome '.claude\skills'
        SkillLayout   = 'folder'   # 每個技能一個資料夾
        # 未實測出載入上限，暫不檢查
        RulesSizeLimit = $null
        Verified      = $true
    }
    gemini = @{
        # 依據 Antigravity 官方文件（~/.gemini/antigravity/builtin/skills/agy-customizations/）：
        # 全域 customization root 是 ~/.gemini/config/，技能放其下的 skills/。
        # 舊路徑 ~/.gemini/antigravity/global_skills 已於 2026-05 遷移淘汰，不再被讀取。
        Name          = 'Gemini / Antigravity'
        RulesFile     = Join-Path $UserHome '.gemini\GEMINI.md'
        SkillsDir     = Join-Path $UserHome '.gemini\config\skills'
        SkillLayout   = 'folder'
        # 實測值：規則檔超過 23,999 bytes 會被靜默截斷（尾端內容不會載入）
        RulesSizeLimit = 23999
        Verified      = $true
    }
    codex = @{
        # 警告：本機未安裝 Codex，以下路徑未經實證，屬暫定值。
        #       確認實際路徑後改這裡，不要改其他地方。
        Name          = 'Codex'
        RulesFile     = Join-Path $UserHome '.codex\AGENTS.md'
        SkillsDir     = Join-Path $UserHome '.codex\skills'
        SkillLayout   = 'folder'
        RulesSizeLimit = $null
        Verified      = $false
    }
}

# 距離上限少於這個位元組數就提前警告，避免下次小改就爆掉
$SizeWarnMargin = 2000

# 全局準則走「規則通道」，不重複進技能通道，避免同一份條文被載入兩次
$RulesSkillName = 'global-rules'

# ---------------------------------------------------------------------------
# 參數處理
# ---------------------------------------------------------------------------
if (Test-PathMangled $Root) {
    Fail $EXIT_PATH_MANGLED @"
-Root 參數的路徑分隔符被 shell 吃掉了：'$Root'
       正確寫法：-Root "D:\AntiGravity-Skill"  或  -Root D:/AntiGravity-Skill
"@
}

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent $PSScriptRoot
}
$Root = (Resolve-Path -LiteralPath $Root -ErrorAction SilentlyContinue).Path
if ([string]::IsNullOrWhiteSpace($Root)) {
    Fail $EXIT_SOURCE_MISSING "來源倉庫路徑不存在，請用 -Root 指定 AntiGravity-Skill 根目錄"
}

$RulesSource = Join-Path $Root "$RulesSkillName\SKILL.md"
if (-not (Test-Path -LiteralPath $RulesSource)) {
    Fail $EXIT_SOURCE_MISSING "找不到全局準則本體：$RulesSource"
}

# 無 -Mode 時顯示選單（人工執行用；自動化請直接帶參數）
if ([string]::IsNullOrWhiteSpace($Mode)) {
    Write-Host ""
    Write-Host "AntiGravity-Skill 同步工具" -ForegroundColor Cyan
    Write-Host "來源：$Root"
    Write-Host ""
    Write-Host "  1. 全局準則覆蓋（rules）"
    Write-Host "  2. SKILL 覆蓋（skills）"
    Write-Host "  3. 全部覆蓋（all）"
    Write-Host "  0. 離開"
    Write-Host ""
    $choice = Read-Host "請選擇"
    switch ($choice) {
        '1' { $Mode = 'rules' }
        '2' { $Mode = 'skills' }
        '3' { $Mode = 'all' }
        '0' { Write-Host "已取消"; exit $EXIT_OK }
        default { Fail $EXIT_BAD_ARGS "無效的選項：$choice" }
    }
}

$syncRules  = ($Mode -eq 'rules')  -or ($Mode -eq 'all')
$syncSkills = ($Mode -eq 'skills') -or ($Mode -eq 'all')

if ($Target -eq 'all') {
    $selectedTargets = @($TargetMap.Keys)
} else {
    $selectedTargets = @($Target)
}

# ---------------------------------------------------------------------------
# 備份（不進專案目錄，放系統暫存區；驗證通過後由使用者自行刪除）
# ---------------------------------------------------------------------------
$stamp     = Get-Date -Format 'yyyyMMdd-HHmmss'
$BackupRoot = Join-Path $env:TEMP "antigravity-sync-backup\$stamp"
$backupUsed = $false

# 未預期的中斷錯誤一律收斂成 exit 1，並提醒目標端可能停在半完成狀態
trap {
    Write-Host ""
    Write-Host "[FAIL] 未預期的錯誤：$($_.Exception.Message)" -ForegroundColor Red
    Write-Host "       位置：$($_.InvocationInfo.ScriptLineNumber) 行" -ForegroundColor Red
    if ($script:backupUsed) {
        Write-Host "       目標端可能停在半完成狀態，覆蓋前的備份在：$BackupRoot" -ForegroundColor Red
    }
    Write-Host "       退出碼 1（意義見 tools\README.md）" -ForegroundColor Red
    exit 1
}

# 複製目錄「內容」到目標。
# 注意：通配符必須用 -Path，-LiteralPath 會把 * 當成字面檔名而失敗。
# 來源為空目錄時直接跳過，避免 Copy-Item 因為沒有符合項而報錯。
function Copy-Contents {
    param([string]$SourceDir, [string]$DestDir)
    if (-not (Test-Path -LiteralPath $DestDir)) {
        New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
    }
    $items = @(Get-ChildItem -LiteralPath $SourceDir -Force -ErrorAction SilentlyContinue)
    if ($items.Count -eq 0) { return 0 }
    Copy-Item -Path (Join-Path $SourceDir '*') -Destination $DestDir -Recurse -Force
    return $items.Count
}

function Backup-Existing {
    param([string]$SourcePath, [string]$TargetKey, [string]$Label)
    if (-not (Test-Path -LiteralPath $SourcePath)) { return }
    if ($DryRun) { return }
    try {
        $dest = Join-Path $BackupRoot "$TargetKey\$Label"
        $destParent = Split-Path -Parent $dest
        if (-not (Test-Path -LiteralPath $destParent)) {
            New-Item -ItemType Directory -Path $destParent -Force | Out-Null
        }
        Copy-Item -LiteralPath $SourcePath -Destination $dest -Recurse -Force
        $script:backupUsed = $true
    } catch {
        Fail $EXIT_BACKUP_FAILED "備份失敗，已中止未做任何寫入：$($_.Exception.Message)"
    }
}

# ---------------------------------------------------------------------------
# 蒐集要同步的技能（只認含 SKILL.md 的資料夾——寧可漏報，不可誤報）
# ---------------------------------------------------------------------------
$allDirs = Get-ChildItem -LiteralPath $Root -Directory |
    Where-Object { $_.Name -notmatch '^\.' -and $_.Name -ne 'tools' }

$skillDirs = @()
$notSkill  = @()
foreach ($d in $allDirs) {
    if (Test-Path -LiteralPath (Join-Path $d.FullName 'SKILL.md')) {
        $skillDirs += $d
    } else {
        $notSkill += $d.Name
    }
}
$skillsToSync = $skillDirs | Where-Object { $_.Name -ne $RulesSkillName }

# ---------------------------------------------------------------------------
# 執行
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "===== AntiGravity-Skill 同步 =====" -ForegroundColor Cyan
Write-Host "來源  ：$Root"
Write-Host "模式  ：$Mode"
Write-Host "目標  ：$($selectedTargets -join ', ')"
if ($DryRun) { Write-Host "預演  ：DryRun，不會實際寫入" -ForegroundColor Yellow }
Write-Host ""

if ($notSkill.Count -gt 0) {
    Write-Warn "以下資料夾沒有 SKILL.md，已排除：$($notSkill -join ', ')"
    Write-Host ""
}

$summary = @()
$hadError = $false

foreach ($key in $selectedTargets) {
    $t = $TargetMap[$key]
    Write-Host "--- $($t.Name) ---" -ForegroundColor White

    if (-not $t.Verified) {
        if (-not $AllowUnverified) {
            # 明確指定單一目標卻整個跳過 = 什麼都沒做，不可回 0 讓呼叫端誤判成功
            if ($Target -ne 'all') {
                Fail $EXIT_TARGET_MISSING @"
$($t.Name) 的路徑未經實證（本機未安裝），未執行任何同步。
       確認實際路徑後修改 tools\sync-skills.ps1 頂端的 `$TargetMap，或加 -AllowUnverified 強制執行
"@
            }
            Write-Skip "$($t.Name) 的路徑未經實證（本機未安裝），已跳過。確認路徑後改腳本頂端的目標定義，或加 -AllowUnverified 強制執行"
            $summary += [pscustomobject]@{ 目標 = $t.Name; 全局準則 = '跳過'; 技能 = '跳過'; 備註 = '路徑未驗證' }
            Write-Host ""
            continue
        }
        Write-Warn "$($t.Name) 的路徑未經實證，依 -AllowUnverified 繼續執行"
    }

    $rulesResult  = '-'
    $skillsResult = '-'

    # ---- 全局準則 ----
    if ($syncRules) {
        $rulesTargetDir = Split-Path -Parent $t.RulesFile
        if (-not (Test-Path -LiteralPath $rulesTargetDir)) {
            if ($Target -ne 'all') {
                Fail $EXIT_TARGET_MISSING "目標目錄不存在：$rulesTargetDir（$($t.Name) 可能未安裝）"
            }
            Write-Skip "目標目錄不存在，跳過：$rulesTargetDir"
            $rulesResult = '跳過（目錄不存在）'
        } else {
            Backup-Existing -SourcePath $t.RulesFile -TargetKey $key -Label (Split-Path -Leaf $t.RulesFile)
            if ($DryRun) {
                Write-Step "[預演] $RulesSource  ->  $($t.RulesFile)"
            } else {
                Copy-Item -LiteralPath $RulesSource -Destination $t.RulesFile -Force
            }
            Write-Ok "全局準則 -> $($t.RulesFile)"
            $rulesResult = '已覆蓋'

            # 超過上限會被靜默截斷——尾端章節不會載入，而且代理不一定會說
            if ($t.RulesSizeLimit) {
                $size = (Get-Item -LiteralPath $RulesSource).Length
                $limit = [int]$t.RulesSizeLimit
                if ($size -gt $limit) {
                    Write-Warn "規則檔 $size bytes，超過 $($t.Name) 的載入上限 $limit bytes，尾端 $($size - $limit) bytes 會被截斷且不會載入"
                    $rulesResult = "已覆蓋（⚠️ 超標 $($size - $limit)B）"
                } elseif (($limit - $size) -lt $SizeWarnMargin) {
                    Write-Warn "規則檔 $size bytes，距離上限 $limit 只剩 $($limit - $size) bytes，接近截斷邊緣"
                    $rulesResult = "已覆蓋（餘裕 $($limit - $size)B）"
                } else {
                    Write-Step "大小 $size / $limit bytes，餘裕 $($limit - $size) bytes"
                }
            }

            # 參考知識隨準則一起走，否則 SKILL.md 的 resources/ 指向會斷
            $resSource = Join-Path $Root "$RulesSkillName\resources"
            if (Test-Path -LiteralPath $resSource) {
                # 必須落在規則檔的同層 resources\，SKILL.md §12.2 的相對路徑才成立
                $resTarget = Join-Path $rulesTargetDir 'resources'
                Backup-Existing -SourcePath $resTarget -TargetKey $key -Label 'resources'
                if ($DryRun) {
                    Write-Step "[預演] $resSource  ->  $resTarget"
                } else {
                    Copy-Contents -SourceDir $resSource -DestDir $resTarget | Out-Null
                }
                Write-Ok "參考知識 -> $resTarget"
            }
        }
    }

    # ---- 技能 ----
    if ($syncSkills) {
        if (-not (Test-Path -LiteralPath $t.SkillsDir)) {
            if ($Target -ne 'all') {
                Fail $EXIT_TARGET_MISSING "技能目錄不存在：$($t.SkillsDir)（$($t.Name) 可能未安裝）"
            }
            Write-Skip "技能目錄不存在，跳過：$($t.SkillsDir)"
            $skillsResult = '跳過（目錄不存在）'
        } else {
            # 舊的 .lnk 捷徑一般程式讀不到，會造成「以為同步了其實沒有」
            $lnks = Get-ChildItem -LiteralPath $t.SkillsDir -Filter '*.lnk' -ErrorAction SilentlyContinue
            if ($lnks) {
                Write-Warn "偵測到 $($lnks.Count) 個 .lnk 捷徑（$($lnks.Name -join ', ')）。本工具改用實體資料夾，請自行確認是否移除舊捷徑，避免重複載入"
            }

            $count = 0
            foreach ($s in $skillsToSync) {
                $dest = Join-Path $t.SkillsDir $s.Name
                Backup-Existing -SourcePath $dest -TargetKey $key -Label "skills\$($s.Name)"
                if ($DryRun) {
                    Write-Step "[預演] $($s.Name)  ->  $dest"
                } else {
                    Copy-Contents -SourceDir $s.FullName -DestDir $dest | Out-Null
                }
                $count++
            }
            Write-Ok "技能 $count 個 -> $($t.SkillsDir)"
            Write-Step "（$RulesSkillName 走全局準則通道，不重複放進技能目錄）"
            $skillsResult = "$count 個已覆蓋"
        }
    }

    $summary += [pscustomobject]@{ 目標 = $t.Name; 全局準則 = $rulesResult; 技能 = $skillsResult; 備註 = '' }
    Write-Host ""
}

# ---------------------------------------------------------------------------
# 摘要
# ---------------------------------------------------------------------------
Write-Host "===== 同步結果 =====" -ForegroundColor Cyan
$summary | Format-Table -AutoSize

if ($backupUsed) {
    Write-Host "備份位置：$BackupRoot" -ForegroundColor Yellow
    Write-Host "確認同步結果無誤後請自行刪除備份（本工具刻意不自動刪）。" -ForegroundColor Yellow
    Write-Host ""
}

if ($DryRun) {
    Write-Host "以上為預演結果，未寫入任何檔案。移除 -DryRun 才會實際執行。" -ForegroundColor Yellow
}

if ($hadError) { exit $EXIT_ERROR }
exit $EXIT_OK
