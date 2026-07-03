param(
    [switch] $Force
)

$ErrorActionPreference = "Stop"

Set-Location -LiteralPath $PSScriptRoot

$savePattern = "*Saiyajin x10 random*.sav"
$configName = ".satisfactory-target"
$backupFolderName = ".satisfactory-trio-backups"

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

function Backup-Save {
    param(
        [string] $Path,
        [string] $TargetDir
    )

    $backupDir = Join-Path $TargetDir $backupFolderName
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

    $name = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    $extension = [System.IO.Path]::GetExtension($Path)
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupPath = Join-Path $backupDir "$name.local-backup-$stamp$extension"

    Copy-Item -LiteralPath $Path -Destination $backupPath -Force
    Write-Host "Backup cree : $backupPath"
}

function Get-RepoMap {
    $map = @{}
    foreach ($repoSave in (Get-SharedSaves -Directory $PSScriptRoot)) {
        $map[$repoSave.Name.ToLowerInvariant()] = $repoSave
    }

    return $map
}

function Get-ChangedTargetSaves {
    param(
        [string] $TargetDir
    )

    $changed = @()
    $repoMap = Get-RepoMap

    foreach ($targetSave in (Get-SharedSaves -Directory $TargetDir)) {
        $key = $targetSave.Name.ToLowerInvariant()
        if (-not $repoMap.ContainsKey($key)) {
            $changed += $targetSave
            continue
        }

        $repoSave = $repoMap[$key]
        if (Test-SameFile -Left $repoSave.FullName -Right $targetSave.FullName) {
            continue
        }

        $repoHash = (Get-FileHash -LiteralPath $repoSave.FullName -Algorithm SHA256).Hash
        $targetHash = (Get-FileHash -LiteralPath $targetSave.FullName -Algorithm SHA256).Hash
        if ($repoHash -ne $targetHash) {
            $changed += $targetSave
        }
    }

    return @($changed)
}

function Copy-RepoSavesToTarget {
    param(
        [string] $TargetDir
    )

    $repoSaves = Get-SharedSaves -Directory $PSScriptRoot
    if ($repoSaves.Count -eq 0) {
        throw "Aucune save partagee trouvee dans le depot : $savePattern"
    }

    foreach ($repoSave in $repoSaves) {
        $targetSave = Join-Path $TargetDir $repoSave.Name
        if (Test-SameFile -Left $repoSave.FullName -Right $targetSave) {
            continue
        }

        if ($Force -and (Test-Path -LiteralPath $targetSave -PathType Leaf)) {
            $repoHash = (Get-FileHash -LiteralPath $repoSave.FullName -Algorithm SHA256).Hash
            $targetHash = (Get-FileHash -LiteralPath $targetSave -Algorithm SHA256).Hash
            if ($repoHash -ne $targetHash) {
                Backup-Save -Path $targetSave -TargetDir $TargetDir
            }
        }

        Copy-Item -LiteralPath $repoSave.FullName -Destination $targetSave -Force
    }
}

$targetDir = Get-TargetDir

git lfs install --local | Out-Null

$dirtyRepoSaves = git status --porcelain -- $savePattern
if ($dirtyRepoSaves -and -not $Force) {
    Write-Host "La copie Git des saves partagees a des changements locaux."
    Write-Host "Si tu viens de jouer, lance plutot .\push-shared-save.ps1"
    Write-Host "Sinon, relance avec -Force pour l'ecraser."
    exit 1
}

$changedTargetSaves = Get-ChangedTargetSaves -TargetDir $targetDir
if ($changedTargetSaves.Count -gt 0 -and -not $Force) {
    Write-Host "Le dossier Satisfactory contient des saves partagees differentes de Git :"
    foreach ($save in $changedTargetSaves) {
        Write-Host "- $($save.Name)"
    }
    Write-Host "Si tu viens de jouer, lance .\push-shared-save.ps1"
    Write-Host "Sinon, relance avec -Force pour recuperer la version Git."
    exit 1
}

git fetch origin main
git pull --ff-only origin main
git lfs pull

Copy-RepoSavesToTarget -TargetDir $targetDir

Write-Host "OK - saves Git copiees vers Satisfactory : $targetDir"
