param(
    [string] $SaveDir
)

$ErrorActionPreference = "Stop"

Set-Location -LiteralPath $PSScriptRoot

$savePattern = "*Saiyajin x10 random*.sav"
$configName = ".satisfactory-target"
$backupFolderName = ".satisfactory-trio-backups"

function Get-SharedSaves {
    param(
        [string] $Directory
    )

    return @(Get-ChildItem -LiteralPath $Directory -File -Filter $savePattern | Sort-Object Name)
}

function Get-SelectedSaveDir {
    param(
        [string] $ProvidedSaveDir
    )

    if ($ProvidedSaveDir) {
        if (-not (Test-Path -LiteralPath $ProvidedSaveDir -PathType Container)) {
            throw "Dossier introuvable : $ProvidedSaveDir"
        }

        return (Resolve-Path -LiteralPath $ProvidedSaveDir).Path
    }

    $root = Join-Path $env:LOCALAPPDATA "FactoryGame\Saved\SaveGames"
    if (-not (Test-Path -LiteralPath $root -PathType Container)) {
        throw "Dossier Satisfactory introuvable : $root. Lance le jeu et cree une save une fois, puis relance ce script."
    }

    $dirs = @(Get-ChildItem -LiteralPath $root -Directory |
        Where-Object { $_.Name -notin @("blueprints", "server") } |
        Sort-Object LastWriteTime -Descending)

    if ($dirs.Count -eq 0) {
        throw "Aucun dossier joueur trouve dans : $root"
    }

    if ($dirs.Count -eq 1) {
        return $dirs[0].FullName
    }

    Write-Host "Choisis le dossier joueur Satisfactory :"
    for ($i = 0; $i -lt $dirs.Count; $i++) {
        $index = $i + 1
        Write-Host "$index. $($dirs[$i].Name) - modifie le $($dirs[$i].LastWriteTime)"
    }

    do {
        $answer = Read-Host "Numero"
        $choice = 0
        $valid = [int]::TryParse($answer, [ref] $choice) -and $choice -ge 1 -and $choice -le $dirs.Count
    } while (-not $valid)

    return $dirs[$choice - 1].FullName
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

function Copy-SaveWithBackup {
    param(
        [string] $Source,
        [string] $Destination,
        [string] $TargetDir
    )

    $sourcePath = (Resolve-Path -LiteralPath $Source).Path

    if (Test-Path -LiteralPath $Destination -PathType Leaf) {
        $destinationPath = (Resolve-Path -LiteralPath $Destination).Path
        if ($sourcePath -ieq $destinationPath) {
            return
        }

        $sourceHash = (Get-FileHash -LiteralPath $Source -Algorithm SHA256).Hash
        $destinationHash = (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash
        if ($sourceHash -ne $destinationHash) {
            Backup-Save -Path $Destination -TargetDir $TargetDir
        }
    }

    Copy-Item -LiteralPath $Source -Destination $Destination -Force
}

git lfs install --local | Out-Null
git lfs pull

$repoSaves = Get-SharedSaves -Directory $PSScriptRoot
if ($repoSaves.Count -eq 0) {
    throw "Aucune save partagee trouvee dans le depot : $savePattern"
}

$targetDir = Get-SelectedSaveDir -ProvidedSaveDir $SaveDir
$repoNames = @{}
foreach ($repoSave in $repoSaves) {
    $repoNames[$repoSave.Name.ToLowerInvariant()] = $true
}

$targetSaves = Get-SharedSaves -Directory $targetDir
foreach ($targetSave in $targetSaves) {
    $key = $targetSave.Name.ToLowerInvariant()
    if (-not $repoNames.ContainsKey($key)) {
        Backup-Save -Path $targetSave.FullName -TargetDir $targetDir
        Remove-Item -LiteralPath $targetSave.FullName
    }
}

foreach ($repoSave in $repoSaves) {
    $targetSave = Join-Path $targetDir $repoSave.Name
    Copy-SaveWithBackup -Source $repoSave.FullName -Destination $targetSave -TargetDir $targetDir
}

Set-Content -LiteralPath (Join-Path $PSScriptRoot $configName) -Value $targetDir -Encoding ASCII

Write-Host "OK - depot relie au dossier Satisfactory : $targetDir"
Write-Host "Saves partagees : $($repoSaves.Count)"
Write-Host "Avant de jouer : .\pull-shared-save.ps1"
Write-Host "Apres avoir joue : .\push-shared-save.ps1 `"message`""
