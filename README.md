# Satisfactory Trio Save

Ce depot partage uniquement cette save :

```text
Saiyajin x10 random MANUAL.sav
```

Les autres saves Satisfactory restent dans le dossier du joueur et ne sont jamais ajoutees a Git.

## Premiere installation

Clonez le depot ou vous voulez, par exemple dans `Documents` :

```powershell
git clone https://github.com/llccrr/satisfactory-trio.git
cd satisfactory-trio
.\init-first-time.ps1
```

Si PowerShell bloque les scripts :

```powershell
powershell -ExecutionPolicy Bypass -File .\init-first-time.ps1
```

Le script :

- trouve `%LOCALAPPDATA%\FactoryGame\Saved\SaveGames`
- demande quel dossier joueur utiliser s'il en voit plusieurs
- sauvegarde automatiquement une save locale du meme nom avant de la remplacer
- memorise ce dossier dans `.satisfactory-target`, un fichier local ignore par Git

## Routine normale

Avant de lancer Satisfactory :

```powershell
.\pull-shared-save.ps1
```

Apres avoir quitte Satisfactory et fait une save manuelle :

```powershell
.\push-shared-save.ps1 "Session du soir"
```

## Regle d'or

Une seule personne modifie et pousse la save a la fois. Les saves Satisfactory sont des fichiers binaires : Git ne peut pas fusionner deux parties differentes jouees en parallele.
