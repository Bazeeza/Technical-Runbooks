# Déploiement de logiciels sous Windows (winget et MSI)

[![Français](https://img.shields.io/badge/Langue-Français-3fe0a0?style=for-the-badge)](README.fr.md)
[![English](https://img.shields.io/badge/Language-English-2b9dff?style=for-the-badge)](README.md)

![Level](https://img.shields.io/badge/Level-Beginner%20to%20Intermediate-ffb454?style=flat-square)
![Time](https://img.shields.io/badge/Time-15%20min-2b9dff?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%2F%2011-0078D6?style=flat-square)
![Reviewed](https://img.shields.io/badge/Last%20reviewed-2026--11-555?style=flat-square)

| Élément | Contenu |
|---|---|
| **Référent** | Installer, vérifier, mettre à jour et désinstaller des logiciels sous Windows en ligne de commande, en mode silencieux et de façon reproductible. |
| **Émetteur** | **bazeeza** |
| **Message** | Installer les logiciels de la même façon sur chaque poste, sans cliquer dans des assistants, et prouver que l'installation a réussi. |
| **Récepteur** | Techniciens de soutien, administrateurs système débutants. |
| **Canal** | Dépôt GitHub `Bazeeza/Technical-Runbooks` |
| **Code** | Français, rédaction technique (traduction de l'original anglais) · PowerShell |
| **Référence** | [Microsoft: winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/) · [winget pin](https://learn.microsoft.com/en-us/windows/package-manager/winget/pinning) · [msiexec](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/msiexec) · [MSI error codes](https://learn.microsoft.com/en-us/windows/win32/msi/error-codes) |

---

## Objectif

Cliquer « Suivant, Suivant, Terminer » sur vingt PC est lent et donne un résultat différent à chaque fois. Une **installation silencieuse** (sans interaction de l'utilisateur) est plus rapide, peut être scriptée et laisse un journal qui prouve ce qui a été fait. Ce runbook couvre les deux méthodes qu'un technicien rencontre tous les jours : **winget** (le gestionnaire de paquets de Windows) et les **paquets MSI**, ainsi que le script [`Install-StandardApps.ps1`](Install-StandardApps.ps1) qui installe une liste standard d'applications en une seule commande.

## Prérequis

- [ ] Windows 10 (1809 ou plus récent) ou Windows 11, avec *Programme d'installation d'application* (App Installer) à jour (`winget --version` répond)
- [ ] Des droits d'administrateur pour les logiciels installés pour tous les utilisateurs
- [ ] La liste des logiciels approuvés : n'installer que ce que l'organisation autorise
- [ ] Un accès à Internet, ou au partage interne de logiciels pour les fichiers MSI

---

## Méthode 1 — winget (recommandée)

winget télécharge les logiciels depuis un dépôt contrôlé, vérifie l'empreinte (*hash*) de l'installateur et l'installe en mode silencieux.

### Étape 1 — Trouver l'identifiant exact du paquet

```powershell
winget search firefox
```

Utilisez la colonne **Id** (par ex. `Mozilla.Firefox`). Un identifiant est exact ; un nom peut correspondre à plusieurs paquets.

### Étape 2 — Installer en mode silencieux

```powershell
winget install --id Mozilla.Firefox --exact --silent --accept-package-agreements --accept-source-agreements
```

| Option | Pourquoi |
|---|---|
| `--id ... --exact` | Installe exactement ce paquet, jamais un paquet au nom semblable |
| `--silent` | Aucune fenêtre, aucune question à l'utilisateur |
| `--accept-...-agreements` | Accepte les licences à l'avance, sinon la commande attend une réponse |
| `--scope machine` | (facultatif) installe pour tous les utilisateurs quand le paquet le permet |

### Étape 3 — Vérifier

```powershell
winget list --id Mozilla.Firefox --exact
```

**Résultat attendu :** une ligne avec le nom, l'identifiant et la version installée.

### Maintenance

```powershell
winget upgrade                                   # list available updates
winget upgrade --all --silent --accept-package-agreements --accept-source-agreements
winget uninstall --id Mozilla.Firefox --exact --silent
winget export -o apps.json                       # save the list of installed software
winget import -i apps.json --accept-package-agreements --accept-source-agreements   # reinstall it on another PC
```

Les commentaires signifient, dans l'ordre : lister les mises à jour disponibles ; enregistrer la liste des logiciels installés ; la réinstaller sur un autre PC.

---

## Méthode 2 — Paquet MSI (msiexec)

Beaucoup d'applications d'entreprise sont distribuées sous forme de fichiers `.msi`, le format standard du déploiement en entreprise (GPO, Intune, Configuration Manager).

### Installer en mode silencieux avec un journal

```powershell
New-Item -ItemType Directory -Force C:\Temp | Out-Null
Start-Process msiexec.exe -Wait -PassThru -ArgumentList '/i "\\fileserver\software\app.msi" /qn /norestart /l*v "C:\Temp\app-install.log"'
```

| Option | Signification |
|---|---|
| `/i` | Installer |
| `/qn` | Silencieux, sans interface |
| `/norestart` | Ne jamais redémarrer le PC automatiquement : l'utilisateur pourrait perdre son travail |
| `/l*v fichier` | Journal détaillé, indispensable pour le diagnostic |

### Lire le code de sortie

`-PassThru` renvoie le processus ; sa propriété `ExitCode` indique ce qui s'est passé :

| Code | Signification | Action |
|---|---|---|
| `0` | Succès | Aucune |
| `3010` | Succès, **redémarrage nécessaire** | Planifier un redémarrage avec l'utilisateur |
| `1603` | Erreur fatale pendant l'installation | Lire le journal : chercher `Return value 3` |
| `1618` | Une autre installation est déjà en cours | Attendre et réessayer |
| `1619` | Le paquet n'a pas pu être ouvert | Vérifier le chemin et les droits d'accès |

### Désinstaller

```powershell
# Find the product code (GUID) in the registry
Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*,
                 HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Where-Object DisplayName -like '*App Name*' |
    Select-Object DisplayName, DisplayVersion, PSChildName

msiexec /x "{PRODUCT-CODE-GUID}" /qn /norestart
```

Le commentaire signifie : trouver le code du produit (GUID) dans le registre.

> [!WARNING]
> Évitez `Get-WmiObject Win32_Product` pour lister les logiciels : cette requête oblige Windows à vérifier, et parfois à **réparer**, chaque produit MSI installé. Lisez plutôt les clés de registre ci-dessus.

### Installateurs EXE

Les installateurs `.exe` n'ont pas de commutateurs standard. Les plus courants dépendent de l'outil qui a construit l'installateur :

| Type d'installateur | Commutateur silencieux |
|---|---|
| NSIS | `/S` (S majuscule) |
| Inno Setup | `/VERYSILENT /NORESTART` |
| InstallShield (avec MSI intégré) | `/s /v"/qn"` |

Confirmez toujours dans la documentation de l'éditeur et testez d'abord sur un seul PC.

---

## Installer un ensemble standard d'applications en une commande

Le script [`Install-StandardApps.ps1`](Install-StandardApps.ps1) lit une liste d'identifiants winget, ignore les logiciels déjà présents, installe le reste, **vérifie** chaque résultat et écrit un journal.

```powershell
# Preview what would be installed, without changing anything
.\Install-StandardApps.ps1 -WhatIf

# Install
.\Install-StandardApps.ps1
```

Les commentaires signifient : afficher ce qui serait installé, sans rien modifier ; installer.

---

## Vérification automatique : Get-InstalledSoftware

La commande `Get-InstalledSoftware` du module PowerShell [Helpdesk Toolkit](https://github.com/Bazeeza/helpdesk-toolkit) fait la recherche dans la section *Uninstall* du registre en une seule commande (Windows PowerShell 5.1 ou PowerShell 7, lecture seule, sans droits d'administrateur). Elle lit les trois mêmes listes que *Applications installées* : 64 bits, 32 bits (`WOW6432Node`) et les programmes installés pour l'utilisateur actuel seulement (`HKCU`), que la commande `HKLM` ci-dessus ne voit pas.

```powershell
Import-Module .\HelpdeskToolkit\HelpdeskToolkit.psd1
Get-InstalledSoftware -Name '*Firefox*'                     # name, version, publisher, install date, scope, architecture
Get-InstalledSoftware -Name '*App Name*' | Select-Object Name, Version, ProductCode, QuietUninstallString
Get-InstalledSoftware | Export-Csv -Path .\software.csv -NoTypeInformation -Encoding UTF8   # before/after list for the ticket
```

Les commentaires signifient : nom, version, éditeur, date d'installation, portée, architecture ; liste avant/après pour le billet.

Elle n'interroge jamais `Win32_Product` (voir l'avertissement ci-dessus). Elle fonctionne aussi pour les logiciels que winget ne gère pas, comme les paquets MSI déployés par GPO. Détails : [référence de Get-InstalledSoftware](https://github.com/Bazeeza/helpdesk-toolkit/blob/main/docs/commands/Get-InstalledSoftware.md).

---

## Vérification

- [ ] Chaque application apparaît dans `winget list` ou dans **Paramètres → Applications → Applications installées**
- [ ] Chaque application s'ouvre pour un utilisateur standard
- [ ] Les codes de sortie et les journaux sont joints au billet

## Dépannage

| Symptôme | Cause probable | Correction |
|---|---|---|
| `winget` n'est pas reconnu | App Installer absent ou pas à jour | Mettre à jour **App Installer** depuis le Microsoft Store |
| L'installation se bloque | Une licence ou une question attend une réponse | Ajouter `--accept-package-agreements --accept-source-agreements` et `--silent` |
| `Installer hash does not match` | L'éditeur a changé le fichier, le dépôt n'est pas encore à jour | Lancer `winget source update` et réessayer plus tard ; ne jamais contourner la vérification de l'empreinte |
| Code MSI `1603` | Droits insuffisants, ancienne version présente, prérequis manquant | Lire le journal `/l*v`, lancer en administrateur, retirer l'ancienne version |
| Code MSI `1618` encore et encore | Windows Update ou un autre installateur tient le verrou de Windows Installer | Attendre la fin, ou redémarrer le PC, puis réessayer |
| `winget` fonctionne dans votre session mais pas dans un script lancé en SYSTEM | winget est installé par utilisateur avec App Installer | Lancer le script dans une session d'utilisateur administrateur, ou déployer avec la méthode MSI |
| Plusieurs paquets correspondent au nom | Recherche par nom au lieu de l'identifiant | Utiliser `--id <Id> --exact`, copié de la colonne **Id** |

## Retour arrière

| Ce qui a été fait | Comment l'annuler |
|---|---|
| Installation winget | `winget uninstall --id <Id> --exact --silent`, puis `winget list --id <Id> --exact` ne renvoie plus rien |
| Mise à niveau winget qui a cassé une application | Désinstaller, puis réinstaller la version précédente : `winget show --id <Id> --versions` les liste, `winget install --id <Id> --exact --version <x.y.z>` en installe une, et `winget pin add --id <Id>` empêche `upgrade --all` de la remettre à jour |
| Installation MSI | `msiexec /x "{PRODUCT-CODE-GUID}" /qn /norestart /l*v "C:\Temp\app-uninstall.log"` (code du produit trouvé comme montré ci-dessus) |
| Ensemble standard d'applications | Désinstaller seulement les identifiants que le journal du script marque `installed and verified` ; les lignes marquées `already installed, skipped` étaient là avant et restent |

Gardez le journal de désinstallation avec le billet, comme le journal d'installation.

---

<sub>Écrit par bazeeza · Vous avez trouvé une erreur ? <a href="https://github.com/Bazeeza/Technical-Runbooks/issues/new?template=runbook-error.yml">Signalez-la ici</a>.</sub>
