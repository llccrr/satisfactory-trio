param(
    [string] $Message
)

$ErrorActionPreference = "Stop"

Set-Location -LiteralPath $PSScriptRoot

$saveName = "Saiyajin x10 random MANUAL.sav"

if (-not (Test-Path -LiteralPath $saveName)) {
    throw "Save introuvable : $saveName"
}

git lfs install --local | Out-Null

$remoteMain = git rev-parse --verify origin/main 2>$null
if ($LASTEXITCODE -eq 0) {
    git fetch origin main
    $behind = [int](git rev-list --count HEAD..origin/main)
    if ($behind -gt 0) {
        Write-Host "La remote contient deja une version plus recente."
        Write-Host "Lance .\pull-shared-save.ps1 avant de jouer, puis reessaie."
        exit 1
    }
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

Write-Host "OK - save partagee poussee : $saveName"
