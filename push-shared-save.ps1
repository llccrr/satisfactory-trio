param(
    [string] $Message
)

$ErrorActionPreference = "Stop"

Set-Location -LiteralPath $PSScriptRoot

$saveName = "Saiyajin x10 random MANUAL.sav"
$configName = ".satisfactory-target"
$repoSave = Join-Path $PSScriptRoot $saveName

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

function Test-SameFile {
    param(
        [string] $Left,
        [string] $Right
    )

    if (-not (Test-Path -LiteralPath $Left) -or -not (Test-Path -LiteralPath $Right)) {
        return $false
    }

    return (Resolve-Path -LiteralPath $Left).Path -ieq (Resolve-Path -LiteralPath $Right).Path
}

$targetDir = Get-TargetDir
$targetSave = Join-Path $targetDir $saveName

if (-not (Test-Path -LiteralPath $targetSave -PathType Leaf)) {
    throw "Save introuvable dans Satisfactory : $targetSave"
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

if (-not (Test-SameFile -Left $targetSave -Right $repoSave)) {
    Copy-Item -LiteralPath $targetSave -Destination $repoSave -Force
}

git add -- $saveName

$staged = git diff --cached --name-only -- $saveName
if (-not $staged) {
    Write-Host "Aucun changement a pousser pour : $saveName"
    exit 0
}

if (-not $Message) {
    $Message = "Update shared save $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
}

git commit -m $Message
git push origin main

Write-Host "OK - save Satisfactory poussee vers GitHub : $targetSave"
