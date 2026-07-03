# Satisfactory Trio Save

Ce depot partage toutes les saves dont le nom contient :

```text
Saiyajin x10 random
```

Exemples partages :

```text
Saiyajin x10 random MANUAL.sav
Saiyajin x10 random MANUAL_continue.sav
Saiyajin x10 random_autosave_0.sav
```

Les autres saves Satisfactory restent dans le dossier du joueur et ne sont jamais ajoutees a Git.

## Premiere installation

Clonez le depot ou vous voulez, par exemple dans `Documents` :

```powershell
git clone https://github.com/llccrr/satisfactory-trio.git
cd satisfactory-trio
.\init-first-time.cmd
```

Le script :

- trouve `%LOCALAPPDATA%\FactoryGame\Saved\SaveGames`
- demande quel dossier joueur utiliser s'il en voit plusieurs
- copie toutes les saves `*Saiyajin x10 random*.sav` vers Satisfactory
- sauvegarde les anciennes saves locales du meme prefixe dans `.satisfactory-trio-backups`
- memorise ce dossier dans `.satisfactory-target`, un fichier local ignore par Git

## Routine normale

Avant de lancer Satisfactory :

```powershell
.\pull-shared-save.cmd
```

Apres avoir quitte Satisfactory :

```powershell
.\push-shared-save.cmd "Session du soir"
```

## Regle d'or

Une seule personne modifie et pousse les saves a la fois. Les saves Satisfactory sont des fichiers binaires : Git ne peut pas fusionner deux parties differentes jouees en parallele.
