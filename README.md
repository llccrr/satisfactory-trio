# Satisfactory Trio Save

Ce depot Git partage uniquement cette save :

```text
Saiyajin x10 random MANUAL.sav
```

Toutes les autres saves presentes dans le dossier Satisfactory sont ignorees par Git.

## Routine normale

Avant de lancer Satisfactory :

```powershell
.\pull-shared-save.ps1
```

Apres avoir quitte Satisfactory et fait une save manuelle :

```powershell
.\push-shared-save.ps1
```

Vous pouvez aussi donner un message de commit :

```powershell
.\push-shared-save.ps1 "Session aluminium"
```

## Installation chez un ami qui a deja des saves

1. Trouver son dossier de saves Satisfactory. Il ressemble a :

```text
%LOCALAPPDATA%\FactoryGame\Saved\SaveGames\<VOTRE_ID>
```

2. Ouvrir PowerShell dans ce dossier.

3. Si une save locale porte deja exactement le meme nom, la renommer avant de continuer :

```powershell
Rename-Item -LiteralPath ".\Saiyajin x10 random MANUAL.sav" -NewName "Saiyajin x10 random MANUAL.local-backup.sav"
```

4. Initialiser Git dans le dossier existant, sans toucher aux autres saves :

```powershell
git init
git lfs install
git remote add origin https://github.com/llccrr/satisfactory-trio.git
git fetch origin main
git switch -c main --track origin/main
git lfs pull
```

Les autres `.sav` du dossier restent la, mais Git les ignore.

## Regle d'or

Une seule personne modifie et pousse la save a la fois. Les saves Satisfactory sont des fichiers binaires : Git ne peut pas fusionner deux parties differentes jouees en parallele.
