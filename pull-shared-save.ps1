param(
    [switch] $Force
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

git lfs install --local | Out-Null

$dirtyRepoSave = git status --porcelain -- $saveName
if ($dirtyRepoSave -and -not $Force) {
    Write-Host "La save du depot a des changements locaux."
    Write-Host "Si tu viens de jouer, lance plutot .\push-shared-save.ps1"
    Write-Host "Sinon, relance avec -Force pour l'ecraser."
    exit 1
}

if ((Test-Path -LiteralPath $repoSave -PathType Leaf) -and
    (Test-Path -LiteralPath $targetSave -PathType Leaf) -and
    -not (Test-SameFile -Left $repoSave -Right $targetSave)) {
    $repoHash = (Get-FileHash -LiteralPath $repoSave -Algorithm SHA256).Hash
    $targetHash = (Get-FileHash -LiteralPath $targetSave -Algorithm SHA256).Hash
    if ($repoHash -ne $targetHash -and -not $Force) {
        Write-Host "La save dans Satisfactory differe de la copie du depot."
        Write-Host "Si tu viens de jouer, lance .\push-shared-save.ps1"
        Write-Host "Sinon, relance avec -Force pour recuperer la version Git."
        exit 1
    }
}

git fetch origin main
git pull --ff-only origin main
git lfs pull

if (-not (Test-SameFile -Left $repoSave -Right $targetSave)) {
    Copy-Item -LiteralPath $repoSave -Destination $targetSave -Force
}

Write-Host "OK - save Git copiee vers Satisfactory : $targetSave"
