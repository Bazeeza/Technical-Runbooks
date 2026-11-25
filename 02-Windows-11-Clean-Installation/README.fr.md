# Installation propre de Windows 11

[![Français](https://img.shields.io/badge/Langue-Français-3fe0a0?style=for-the-badge)](README.fr.md)
[![English](https://img.shields.io/badge/Language-English-2b9dff?style=for-the-badge)](README.md)

![Level](https://img.shields.io/badge/Level-Beginner-3fe0a0?style=flat-square)
![Time](https://img.shields.io/badge/Time-60%E2%80%9390%20min-2b9dff?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Windows%2011-0078D6?style=flat-square)
![Reviewed](https://img.shields.io/badge/Last%20reviewed-2026--11-555?style=flat-square)

| Élément | Contenu |
|---|---|
| **Référent** | Installation propre de Windows 11 depuis une clé USB amorçable, sur un PC dont le disque sera effacé. |
| **Émetteur** | **bazeeza** |
| **Message** | Vérifier la compatibilité, créer le support d'installation, installer Windows sur un disque GPT en mode UEFI, et remettre un PC prêt pour l'utilisateur. |
| **Récepteur** | Techniciens de soutien qui préparent ou réinstallent un poste de travail. |
| **Canal** | Dépôt GitHub `Bazeeza/Technical-Runbooks` |
| **Code** | Français, rédaction technique (traduction de l'original anglais) |
| **Référence** | [Windows 11 specifications](https://www.microsoft.com/en-us/windows/windows-11-specifications) · [Download Windows 11](https://www.microsoft.com/en-us/software-download/windows11) · [Windows client deployment](https://learn.microsoft.com/en-us/windows/deployment/) |

---

## Objectif

Réinstaller Windows 11 sur un poste de travail (nouveau disque, logiciel malveillant, système corrompu, changement d'utilisateur) et obtenir un système **propre, à jour et activé**. Une installation propre efface tout le disque cible : la protection des données passe en premier.

> [!NOTE]
> En entreprise, les postes sont généralement déployés avec des outils comme Intune/Autopilot, MDT ou Configuration Manager. Cette procédure manuelle est la base que ces outils automatisent, et elle sert encore pour les réparations ponctuelles.

## Prérequis

- [ ] **Données de l'utilisateur sauvegardées et vérifiées** (ouvrir quelques fichiers depuis la sauvegarde)
- [ ] Une clé USB de **8 Go ou plus** (elle sera effacée)
- [ ] Un autre PC fonctionnel avec un accès à Internet pour créer la clé
- [ ] L'édition de Windows et la licence à installer (licence numérique, clé OEM ou activation en volume de l'organisation)
- [ ] Les pilotes réseau du PC cible, sur une deuxième clé USB (au cas où Windows ne détecte pas la carte réseau)
- [ ] La clé de récupération BitLocker, si le disque est chiffré et que des données doivent d'abord être lues

---

## Étape 1 — Vérifier la compatibilité matérielle

| Exigence | Minimum | Comment vérifier |
|---|---|---|
| Processeur | 64 bits, 1 GHz, 2 cœurs, sur la liste des processeurs pris en charge par Microsoft | `msinfo32` → Processeur |
| RAM | 4 Go | `msinfo32` → Mémoire physique (RAM) installée |
| Stockage | 64 Go | Gestion des disques (`diskmgmt.msc`) |
| Firmware | UEFI compatible Secure Boot | `msinfo32` → Mode BIOS / État du démarrage sécurisé |
| TPM | Version 2.0 | `tpm.msc` → Version de la spécification |
| Carte graphique | DirectX 12 / WDDM 2.0 | `dxdiag` |

Si l'UEFI, Secure Boot ou le TPM est désactivé, activez-le dans le firmware : voir le [runbook 01](../01-PC-Boot-Process-and-BIOS-UEFI/README.fr.md#étape-4--vérifier-le-mode-uefi-et-secure-boot). Dans les menus du firmware, le TPM s'appelle souvent **Intel PTT** ou **AMD fTPM**.

## Étape 2 — Créer la clé USB d'installation

Sur le PC fonctionnel :

1. Téléchargez l'**outil de création de support** (Media Creation Tool) depuis la page officielle de Microsoft (lien dans l'en-tête). N'utilisez jamais un ISO venant d'une source non officielle.
2. Lancez-le, acceptez la licence, choisissez la langue et l'édition, sélectionnez **Disque mémoire flash USB**, puis choisissez la clé.
3. Attendez la fin du téléchargement et de la création (15 à 30 min selon la connexion).

**Résultat attendu :** la clé s'appelle `ESD-USB` et contient `setup.exe`, `boot`, `efi` et `sources`.

> [!TIP]
> **Rufus** (logiciel libre) est une autre solution quand on part d'un fichier ISO. Choisissez le schéma de partition **GPT** et le système de destination **UEFI (non CSM)**.

## Étape 3 — Démarrer le PC cible sur la clé

1. Branchez la clé sur le PC cible.
2. Ouvrez le **menu de démarrage ponctuel** (`F12` sur Dell et Lenovo, `Esc` puis `F9` sur HP ; tableau complet dans le [runbook 01](../01-PC-Boot-Process-and-BIOS-UEFI/README.fr.md#étape-1--entrer-dans-la-configuration-du-firmware)).
3. Choisissez l'entrée qui commence par **UEFI:** suivie du nom de la clé.

**Résultat attendu :** l'écran *Installation de Windows* apparaît. Choisir une entrée sans `UEFI:` lancerait l'installateur en mode hérité et créerait un disque MBR incompatible avec Windows 11.

## Étape 4 — Lancer l'installateur

1. Choisissez la langue, le format de l'heure et le **clavier** (par ex. *Canadien français* ou *US*), puis **Suivant → Installer Windows 11**.
2. **Clé de produit :** saisissez-la, ou choisissez **Je n'ai pas de clé de produit** si le PC a déjà une licence numérique (il s'active automatiquement une fois en ligne).
3. Choisissez l'**édition** qui correspond à la licence (Famille, Professionnel...). Une mauvaise édition ne s'activera pas.
4. Acceptez la licence, puis choisissez l'**installation personnalisée** (installation propre), pas la mise à niveau.

## Étape 5 — Préparer le disque

Sur l'écran de sélection du disque :

1. Identifiez le disque cible par sa **taille** (le disque 0 est généralement le disque interne).
2. Sélectionnez chaque partition de ce disque et cliquez sur **Supprimer** jusqu'à ce qu'il ne reste que de l'**espace non alloué**.
3. Sélectionnez l'espace non alloué et cliquez sur **Suivant**. Windows crée lui-même les partitions nécessaires (EFI, MSR, Windows, récupération) en **GPT**.

> [!CAUTION]
> Supprimer des partitions efface leurs données **définitivement**. Débranchez tout autre disque interne ou externe s'il y a le moindre doute sur le disque cible.

**Résultat attendu :** les fichiers sont copiés, puis le PC redémarre plusieurs fois. Retirez la clé USB au premier redémarrage si le PC relance l'installateur.

## Étape 6 — Configuration initiale (OOBE)

1. Région et disposition du clavier.
2. **Réseau :** connectez-vous en Wi-Fi ou en Ethernet. Si aucun réseau n'est détecté, installez le pilote réseau depuis la deuxième clé USB.
3. Nom de l'appareil, puis type de compte :
   - **Appareil personnel :** compte Microsoft (exigé par Windows 11 Famille).
   - **Appareil d'entreprise (Pro/Entreprise) :** **Configurer pour le travail ou l'école** pour joindre Entra ID / Intune, ou un compte local puis la jonction au domaine (étape suivante).
4. Définissez un code PIN, revoyez les paramètres de confidentialité en tenant compte de la politique de l'organisation (désactivez ce qui n'est pas nécessaire).

**Résultat attendu :** le bureau de Windows apparaît.

## Étape 7 — Terminer le poste

Suivez la [liste de vérification après installation](POST-INSTALL-CHECKLIST.fr.md) complète : mises à jour, pilotes, activation, sécurité, nommage, jonction au domaine.

---

## Vérification

Avant de remettre le PC, prouvez que l'installation elle-même est correcte :

```powershell
Get-ComputerInfo -Property OsName, OsVersion, BiosFirmwareType   # edition, build, and "Uefi"
Get-Disk | Select-Object Number, PartitionStyle, Size              # the system disk shows GPT
Confirm-SecureBootUEFI                                             # administrator; True
slmgr /xpr                                                         # dialog box: "permanently activated"
```

Les commentaires signifient, dans l'ordre : l'édition, la version et « Uefi » ; le disque système affiche GPT ; commande d'administrateur, résultat `True` ; une boîte de dialogue indique que Windows est activé de façon permanente.

- [ ] L'édition correspond à la licence, le type de firmware est **UEFI**, le disque est **GPT**, Secure Boot renvoie `True`
- [ ] Windows est activé (**Paramètres → Système → Activation**)
- [ ] Le **Gestionnaire de périphériques** n'affiche aucun appareil avec un triangle jaune d'avertissement
- [ ] La [liste de vérification après installation](POST-INSTALL-CHECKLIST.fr.md) est complète et jointe au billet

## Dépannage

| Symptôme | Cause probable | Correction |
|---|---|---|
| « Ce PC ne peut pas exécuter Windows 11 » | TPM ou Secure Boot désactivé | Les activer dans le firmware, relancer l'installation |
| « Impossible d'installer Windows sur ce disque. Le disque sélectionné est du style de partition MBR » | Installateur lancé en mode hérité | Redémarrer et choisir l'entrée de démarrage qui commence par **UEFI:** |
| Aucun disque dans la liste | Pilote de stockage manquant (Intel RST/VMD) | **Charger un pilote** avec le pilote de stockage du fabricant sur une clé USB, ou passer le mode SATA en AHCI sur un disque **vide** |
| Redémarrage sans fin dans l'installation | Clé USB encore en premier dans l'ordre de démarrage | Retirer la clé, mettre Windows Boot Manager en premier |
| Aucun réseau pendant l'OOBE | Pilote réseau manquant | L'installer depuis la deuxième clé USB (`Charger un pilote` ou par l'Explorateur de fichiers une fois sur le bureau) |

## Retour arrière

Une installation propre ne peut pas être annulée : les anciennes partitions disparaissent dès que l'étape 5 est confirmée. C'est pour cela que la sauvegarde est le premier prérequis.

- **Avant l'étape 5 :** rien n'a encore été écrit. Fermez l'installateur et redémarrez sans la clé USB : l'ancien système démarre comme avant.
- **Après l'étape 5 :** restaurez les données de l'utilisateur depuis la sauvegarde vérifiée, ou réinstallez le PC avec l'image standard de l'organisation. Un dossier `Windows.old` n'existe qu'après une mise à niveau ou une réinstallation **sans** suppression des partitions, pas après cette procédure.

---

<sub>Écrit par bazeeza · Vous avez trouvé une erreur ? <a href="https://github.com/Bazeeza/Technical-Runbooks/issues/new?template=runbook-error.yml">Signalez-la ici</a>.</sub>
