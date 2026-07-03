param(
    [string] $Message
)

$ErrorActionPreference = "Stop"

Set-Location -LiteralPath $PSScriptRoot

$savePattern = "*Saiyajin x10 random*.sav"
$configName = ".satisfactory-target"

function Get-TargetDir {
    $configPath = Join-Path $PSScriptRoot $configName
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        throw "Init manquante. Lance d'abord .\init-first-time.ps1"
    }

    $targetDir = (Get-Content -LiteralPath $configPath -Raw).Trim()
    if (-not (Test-Path -LiteralPath $targetDir -PathType Container)) {
        throw "Dossier Satisfactory introuvable : $targetDir. Relance .\init-first-time.ps1"
    }

    return (Resolve-Path -LiteralPath $targetDir).Path
}

function Get-SharedSaves {
    param(
        [string] $Directory
    )

    return @(Get-ChildItem -LiteralPath $Directory -File -Filter $savePattern | Sort-Object Name)
}

function Test-SameFile {
    param(
        [string] $Left,
        [string] $Right
    )

    if (-not (Test-Path -LiteralPath $Left -PathType Leaf) -or -not (Test-Path -LiteralPath $Right -PathType Leaf)) {
        return $false
    }

    return (Resolve-Path -LiteralPath $Left).Path -ieq (Resolve-Path -LiteralPath $Right).Path
}

$targetDir = Get-TargetDir
$targetSaves = Get-SharedSaves -Directory $targetDir

if ($targetSaves.Count -eq 0) {
    throw "Aucune save a pousser dans Satisfactory : $savePattern"
}

git lfs install --local | Out-Null
git fetch origin main

$remoteMain = git rev-parse --verify origin/main 2>$null
if ($LASTEXITCODE -eq 0) {
    $behind = [int](git rev-list --count HEAD..origin/main)
    if ($behind -gt 0) {
        Write-Host "La remote contient deja une version plus recente."
        Write-Host "Lance .\pull-shared-save.ps1 avant de jouer, puis reessaie."
        exit 1
    }
}

foreach ($targetSave in $targetSaves) {
    $repoSave = Join-Path $PSScriptRoot $targetSave.Name
    if (Test-SameFile -Left $targetSave.FullName -Right $repoSave) {
        continue
    }

    Copy-Item -LiteralPath $targetSave.FullName -Destination $repoSave -Force
}

$repoSaves = Get-SharedSaves -Directory $PSScriptRoot
foreach ($repoSave in $repoSaves) {
    git add -- $repoSave.Name
}

$staged = git diff --cached --name-only -- $savePattern
if (-not $staged) {
    Write-Host "Aucun changement a pousser pour : $savePattern"
    exit 0
}

if (-not $Message) {
    $Message = "Update shared saves $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
}

git commit -m $Message
git push origin main

Write-Host "OK - saves Satisfactory poussees vers GitHub : $targetDir"
