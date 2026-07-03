param(
    [string] $SaveDir
)

$ErrorActionPreference = "Stop"

Set-Location -LiteralPath $PSScriptRoot

$saveName = "Saiyajin x10 random MANUAL.sav"
$configName = ".satisfactory-target"
$repoSave = Join-Path $PSScriptRoot $saveName

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

function Copy-SaveIfNeeded {
    param(
        [string] $Source,
        [string] $Destination
    )

    $sourcePath = (Resolve-Path -LiteralPath $Source).Path
    $destinationExists = Test-Path -LiteralPath $Destination

    if ($destinationExists) {
        $destinationPath = (Resolve-Path -LiteralPath $Destination).Path
        if ($sourcePath -ieq $destinationPath) {
            return
        }

        $sourceHash = (Get-FileHash -LiteralPath $Source -Algorithm SHA256).Hash
        $destinationHash = (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash
        if ($sourceHash -ne $destinationHash) {
            $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $backup = Join-Path (Split-Path -Parent $Destination) "Saiyajin x10 random MANUAL.local-backup-$stamp.sav"
            Copy-Item -LiteralPath $Destination -Destination $backup
            Write-Host "Backup cree : $backup"
        }
    }

    Copy-Item -LiteralPath $Source -Destination $Destination -Force
}

git lfs install --local | Out-Null
git lfs pull

if (-not (Test-Path -LiteralPath $repoSave -PathType Leaf)) {
    throw "Save du depot introuvable : $repoSave"
}

$targetDir = Get-SelectedSaveDir -ProvidedSaveDir $SaveDir
$targetSave = Join-Path $targetDir $saveName

Set-Content -LiteralPath (Join-Path $PSScriptRoot $configName) -Value $targetDir -Encoding ASCII
Copy-SaveIfNeeded -Source $repoSave -Destination $targetSave

Write-Host "OK - depot relie au dossier Satisfactory : $targetDir"
Write-Host "Avant de jouer : .\pull-shared-save.ps1"
Write-Host "Apres avoir joue : .\push-shared-save.ps1 `"message`""
