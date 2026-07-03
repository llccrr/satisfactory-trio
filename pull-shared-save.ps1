$ErrorActionPreference = "Stop"

Set-Location -LiteralPath $PSScriptRoot

$saveName = "Saiyajin x10 random MANUAL.sav"
$dirty = git status --porcelain -- $saveName

if ($dirty) {
    Write-Host "La save locale a des changements non commit."
    Write-Host "Si tu viens de jouer, lance plutot .\push-shared-save.ps1"
    exit 1
}

git lfs install --local | Out-Null
git fetch origin main
git pull --ff-only origin main
git lfs pull

Write-Host "OK - save partagee synchronisee : $saveName"
