# Sauvegardes Windows : File History, Windows Server Backup et robocopy

[![Français](https://img.shields.io/badge/Langue-Français-3fe0a0?style=for-the-badge)](WINDOWS-BACKUP.fr.md)
[![English](https://img.shields.io/badge/Language-English-2b9dff?style=for-the-badge)](WINDOWS-BACKUP.md)

![Level](https://img.shields.io/badge/Level-Intermediate-ffb454?style=flat-square)
![Time](https://img.shields.io/badge/Time-20%E2%80%9340%20min-2b9dff?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Windows%2011%20%7C%20Windows%20Server%202019%2B-0078D4?style=flat-square)
![Reviewed](https://img.shields.io/badge/Last%20reviewed-2026--10-555?style=flat-square)

| Élément | Contenu |
|---|---|
| **Référent** | Un poste de travail Windows dont les fichiers de l'utilisateur doivent être protégés, ou un serveur de fichiers Windows dont les partages et le système doivent pouvoir être récupérés. |
| **Émetteur** | **bazeeza** |
| **Message** | Choisir l'outil intégré qui convient à la machine, le configurer, puis restaurer dans un dossier séparé et prouver la restauration avec `Test-RestoredFiles.ps1`. |
| **Récepteur** | Techniciens de soutien et administrateurs Windows débutants. |
| **Canal** | Dépôt GitHub `Bazeeza/Technical-Runbooks` |
| **Code** | Français, rédaction technique (traduction de l'original anglais) · Windows PowerShell 5.1, invite de commandes |
| **Référence** | [Microsoft: Back up and restore with File History](https://support.microsoft.com/en-us/windows/backup-and-restore-with-file-history-7bf065bf-f1ea-0a78-c1cf-7dcf51cc8bfc) · [Microsoft: wbadmin start backup](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/wbadmin-start-backup) · [Microsoft: wbadmin start recovery](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/wbadmin-start-recovery) · [Microsoft: robocopy](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/robocopy) · [Microsoft: Return codes used by robocopy](https://learn.microsoft.com/en-us/troubleshoot/windows-server/backup-and-storage/return-codes-used-robocopy-utility) |

---

## Objectif

Donner à chaque machine Windows une sauvegarde adaptée à ce qu'elle contient, et une restauration qui a été **testée**. Ce guide fait partie du [runbook 13](README.fr.md), qui explique la règle 3-2-1 et le registre des tests de restauration.

## Quel outil pour quelle machine

| Machine | Ce qui doit revenir | Outil | Garde les anciennes versions |
|---|---|---|---|
| Poste de travail d'un utilisateur | Documents, bureau, images | **File History** (*Historique des fichiers*) vers un disque externe ou un partage réseau | Oui, toutes les heures par défaut |
| Poste de travail avec OneDrive | Les mêmes dossiers | Sauvegarde des dossiers par OneDrive | Historique des versions et corbeille de OneDrive, pour une durée limitée : une synchronisation, pas une sauvegarde complète |
| Windows Server (serveur de fichiers) | Partages, état du système, volumes entiers | **Windows Server Backup** (`wbadmin`) | Oui, plusieurs versions sur le disque cible |
| N'importe quelle machine, deuxième copie | Un dossier de données | **robocopy** vers un NAS | Non : un miroir, comme rsync |

Dans un domaine, le logiciel de sauvegarde de l'entreprise, s'il y en a un, passe en premier : ces outils sont destinés aux petits sites, aux laboratoires et aux machines isolées.

## Option A — File History (poste de travail)

1. Brancher le disque externe, ou préparer un partage réseau.
2. Ouvrir **Control Panel** › **System and Security** › **Save backup copies of your files with File History** (*Panneau de configuration › Système et sécurité › Enregistrer des copies de sauvegarde de vos fichiers avec l'Historique des fichiers*).
3. Choisir **Select drive** (*Sélectionner un lecteur*) pour indiquer le disque ou l'emplacement réseau, puis **Turn on** (*Activer*).
4. Dans **Advanced settings** (*Paramètres avancés*), régler **Save copies of files** (*Enregistrer des copies des fichiers* ; toutes les heures par défaut) et **Keep saved versions** (*Conserver les versions enregistrées* ; par exemple 3 mois).

File History protège les bibliothèques, le bureau, les contacts et les favoris de l'utilisateur. Il ne sauvegarde **pas** les applications ni Windows lui-même : ceux-ci se réinstallent ([runbooks 02](../02-Windows-11-Clean-Installation/README.fr.md) et [03](../03-Software-Deployment/README.fr.md)).

**Test de restauration :** dans **File Explorer** (*Explorateur de fichiers*), cliquer avec le bouton droit sur le dossier › **Restore previous versions** (*Restaurer les versions précédentes*). Dans l'onglet **Previous Versions** (*Versions précédentes*), choisir une version, puis ouvrir **Restore** › **Restore to...** (*Restaurer › Restaurer vers...*) et choisir un dossier de test vide, pour ne pas écraser les fichiers en service.

**Résultat attendu :** le dossier apparaît à l'emplacement de test avec le contenu qu'il avait à cette date.

## Option B — Windows Server Backup (serveur)

Installer la fonctionnalité, puis lancer une sauvegarde unique vers un disque dédié ou un partage, depuis un PowerShell en administrateur :

```powershell
Install-WindowsFeature -Name Windows-Server-Backup
wbadmin start backup -backupTarget:E: -include:D: -allCritical -quiet
wbadmin get versions
```

- `-include:D:` sauvegarde le volume de données ; `-allCritical` ajoute ce qu'il faut pour une récupération complète du système sur du matériel nu (*bare-metal recovery*).
- `-backupTarget` peut être un volume local ou un partage réseau (`\\<backup-server>\<share>`). Un disque local dédié garde plusieurs versions ; sur un partage réseau, chaque nouvelle sauvegarde **écrase** la précédente, donc une exécution ratée peut vous laisser sans aucune sauvegarde utilisable.
- Pour un horaire quotidien, utiliser **Windows Server Backup** › **Backup Schedule** (*Planification de sauvegarde*), ou `wbadmin enable backup`.

**Test de restauration** d'un dossier vers un autre emplacement (l'identifiant de version vient de `wbadmin get versions`) :

```powershell
wbadmin start recovery -version:<MM/DD/YYYY-HH:MM> -itemType:File -items:D:\Shares\Finance -recoveryTarget:E:\RestoreTest -recursive
```

**Résultat attendu :** `The recovery operation completed successfully` et le dossier sous `E:\RestoreTest`.

> [!WARNING]
> Sans `-recoveryTarget`, les fichiers sont restaurés à leur emplacement **d'origine**. Toujours restaurer un test dans un autre dossier.

## Option C — Miroir robocopy vers un NAS (deuxième copie)

```powershell
robocopy D:\Data \\<nas>\backup\Data /MIR /COPY:DAT /DCOPY:DAT /R:2 /W:5 /L /NP /LOG:C:\Logs\robocopy-data.log
robocopy D:\Data \\<nas>\backup\Data /MIR /COPY:DAT /DCOPY:DAT /R:2 /W:5 /NP /LOG:C:\Logs\robocopy-data.log
$LASTEXITCODE
```

| Option | Pourquoi |
|---|---|
| `/L` (première exécution) | Liste ce qui serait copié **et supprimé**, sans le faire |
| `/MIR` | Miroir exact : **supprime** aussi dans la destination ce qui n'existe plus dans la source |
| `/COPY:DAT /DCOPY:DAT` | Données, attributs et horodatages des fichiers et des dossiers |
| `/R:2 /W:5` | Deux nouvelles tentatives à cinq secondes d'intervalle, au lieu du million de tentatives par défaut |
| `/LOG:` | Un journal à joindre au billet ou à consulter plus tard |

Le code de sortie de robocopy est un ensemble d'indicateurs, pas un simple succès ou échec : **0 à 7 signifie aucun échec**, **8 ou plus signifie qu'au moins un fichier a échoué**. Une tâche planifiée qui traite tout code non nul comme une erreur déclenche de fausses alertes.

> [!CAUTION]
> Un miroir copie aussi les erreurs : un fichier supprimé ou chiffré par un rançongiciel est supprimé ou chiffré dans le miroir à l'exécution suivante. robocopy est une deuxième copie, jamais la seule sauvegarde.

## Prouver la restauration avec Test-RestoredFiles.ps1

Quel que soit l'outil, terminer le test de restauration en comparant le dossier restauré avec l'original :

```powershell
.\Test-RestoredFiles.ps1 -SourcePath D:\Shares\Finance -RestoredPath E:\RestoreTest\Finance -ReportPath .\restore-test.csv
```

| Résultat | Signification |
|---|---|
| Code de sortie **0**, `Restore test PASSED` | Chaque fichier est revenu avec une empreinte SHA-256 identique |
| Code de sortie **1**, lignes `Different` | Le contenu diffère : le fichier a changé après la sauvegarde, ou la copie est endommagée |
| Code de sortie **1**, lignes `Missing` | Fichiers absents de la sauvegarde : vérifier la sélection de la sauvegarde |
| Code de sortie **2** | Un des dossiers n'existe pas |

Les fichiers modifiés entre la sauvegarde et le test apparaissent comme `Different`. Choisir un dossier qui ne change pas pendant la journée, ou expliquer les différences attendues dans le registre.

## Dépannage

| Symptôme | Cause probable | Correction |
|---|---|---|
| File History : `Reconnect your drive` | Disque externe déconnecté ou lettre de lecteur changée | Le rebrancher, ou refaire **Select drive** |
| File History ignore des fichiers | Chemin trop long, ou fichier ouvert et verrouillé | Raccourcir les chemins de dossiers profonds ; les fichiers en cours d'utilisation sont copiés à l'exécution suivante |
| `wbadmin` n'est pas reconnu | Fonctionnalité non installée | `Install-WindowsFeature Windows-Server-Backup` |
| Une seule version sur le partage réseau | Normal : chaque sauvegarde vers le même partage écrase la précédente | Utiliser un disque local dédié pour l'historique, ou un sous-dossier par sauvegarde |
| `wbadmin start recovery` échoue sur des fichiers | Éléments de dossiers parents différents dans une même commande | Restaurer un dossier parent par commande |
| Code de sortie robocopy 8 ou 16 | Accès refusé, chemin introuvable, partage injoignable | Lire les lignes `ERROR` du journal ; vérifier les droits du compte sur le NAS |
| robocopy a supprimé des fichiers dans la copie | `/MIR` et des fichiers retirés de la source | Comportement attendu : les restaurer depuis la vraie sauvegarde, et garder `/L` comme première étape |

---

<sub>Fait partie du [runbook 13, Sauvegarde et restauration](README.fr.md) · Écrit par bazeeza</sub>
