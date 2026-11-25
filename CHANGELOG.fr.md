# Journal des modifications

[![Français](https://img.shields.io/badge/Langue-Français-3fe0a0?style=for-the-badge)](CHANGELOG.fr.md)
[![English](https://img.shields.io/badge/Language-English-2b9dff?style=for-the-badge)](CHANGELOG.md)

Tous les changements notables de ces runbooks sont listés ici.
Le format suit [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), et les versions suivent le [versionnage sémantique](https://semver.org/) : un nouveau runbook est une version mineure, une correction est un correctif (*patch*).

## [Unreleased]

### Ajouté

- 04 Network Troubleshooting : section *Automated check* qui exécute les étapes 1 à 6 avec `Test-NetworkHealth` du module Helpdesk Toolkit.
- 03 Software Deployment : section *Automated check* qui liste les logiciels installés depuis les clés de registre 64 bits, 32 bits et par utilisateur avec `Get-InstalledSoftware` du module Helpdesk Toolkit.
- 01 PC Boot Process, dépannage : section *Automated check* qui vérifie l'état du disque et l'espace libre avec `Get-DiskHealth` du module Helpdesk Toolkit, et une ligne correspondante dans la liste de vérification.
- 04 Network Troubleshooting : la section d'escalade montre comment joindre les étapes réseau sous forme d'un seul fichier HTML avec `Export-HelpdeskReport` du module Helpdesk Toolkit.
- Guide de style de la documentation en anglais et en français (`docs/STYLE.md`, `docs/STYLE.fr.md`) : boutons de langue, tableau « en un coup d'œil », arborescence du dépôt, mise en page, règles de traduction et de confidentialité.
- `scripts/Test-ReadmePair.ps1` : vérifie que chaque document traduit a sa jumelle et ses boutons de langue, et que chaque lien relatif pointe vers un fichier existant ; lancé par le workflow Markdown.
- Tests Pester pour `Test-ReadmePair.ps1`, lancés sous PowerShell 7 et Windows PowerShell 5.1 par le workflow PowerShell.
- README : boutons de langue, tableau « en un coup d'œil » et structure du dépôt avec un lien vers le README de chaque dossier.
- Versions françaises du README, du modèle de runbook, du guide de contribution, de ce journal et du README de l'archive (`*.fr.md`). Les notes d'étude copiées dans `archive/` restent en anglais seulement.
- Versions françaises des runbooks 01 (démarrage et dépannage d'un PC qui ne démarre pas) et 02 (installation propre et liste de vérification après installation).

### Modifié

- README : les niveaux et les couleurs des domaines sont en texte simple (le tableau des couleurs donne le code hexadécimal utilisé par le schéma) au lieu d'emojis, que les lecteurs d'écran annoncent un par un et qui s'affichent différemment selon la plateforme.

## [1.0.0] - 2026-11-02

Première version complète : 15 runbooks qui suivent tous le même modèle, avec des vérifications automatiques à chaque changement.

### Ajouté

- 06 Printer Troubleshooting : file d'impression, Print Spooler, ports réseau 9100/631/515, vérification du port et du pilote, avec `Reset-PrintQueue.ps1` et un guide pour déployer les imprimantes avec les préférences de stratégie de groupe.
- 07 Remote Support : procédure Quick Assist fondée sur le consentement, Bureau à distance avec authentification au niveau du réseau (NLA), et une liste de vérification de sécurité pour l'assistance à distance.
- 08 Network Cabling and Termination : codes de couleurs T568A/T568B avec un schéma de brochage, câble droit ou croisé, limites des Cat 5e/6/6A, sertissage RJ45, un guide de test des câbles avec les défauts de *wire map*, et un guide des panneaux de brassage et de l'étiquetage TIA-606.
- 09 Wi-Fi Troubleshooting : bandes et canaux 2,4/5/6 GHz, `netsh wlan show interfaces` et `show networks mode=bssid`, seuils de signal, corrections de profil et de WPA3, avec `Export-WifiDiagnostics.ps1` et un guide du rapport de réseau sans fil.
- 10 VoIP / SIP Phone Troubleshooting : la chaîne PoE → VLAN voix → enregistrement → SIP → RTP, vérifications Asterisk/FreePBX, audio à sens unique causé par le NAT, le SIP ALG et les ports RTP (UDP 10000–20000), avec un guide du déroulement d'un appel SIP (SDP, codes de réponse) et un guide de préparation du réseau voix (bande passante des codecs, DSCP EF 46, VLAN voix, PoE).
- 11 Cisco Switch Baseline : une configuration complète et commentée de commutateur d'accès (secrets de type 9, bannière, SSH version 2 seulement, VLAN et ACL de gestion, sécurité des ports, portfast et BPDU guard, VLAN « trou noir », trunk restreint avec un VLAN natif inutilisé), avec un guide de sécurité des ports et de récupération des ports err-disabled.
- 12 Linux Server Hardening Basics : clés SSH Ed25519, un fichier complémentaire `sshd_config.d` (`PasswordAuthentication no`, `PermitRootLogin no`, `AllowUsers`), ufw avec refus par défaut et `limit` sur SSH, une prison fail2ban avec bannissements progressifs, mises à jour de sécurité automatiques, et un guide qui explique pourquoi les ports publiés par Docker contournent ufw et comment les lier à `127.0.0.1`.
- 13 Backup and Restore : inventaire RPO et RTO, la règle 3-2-1, un test de restauration obligatoire et consigné, un guide Windows (Historique des fichiers, `wbadmin`, robocopy et ses codes de sortie), un guide Linux (restic avec un minuteur systemd, rétention et `restic check`, rsync comme miroir), et `Test-RestoredFiles.ps1` pour comparer un dossier restauré avec l'original par SHA-256.
- 14 Phishing Report and First Response : reconnaître, signaler avec le bouton **Report** intégré à Outlook, contenir selon ce que l'utilisateur a fait, escalader et consigner ; une liste de premières mesures (réinitialisation du mot de passe, `Revoke-MgUserSignInSession`, revue des méthodes MFA, vérification des transferts et de `Get-InboxRule -IncludeHidden`, isolement du poste), un guide de lecture de SPF, DKIM, DMARC, compauth et de la chaîne Received, et `Get-EmailHeaderSummary.ps1` avec un exemple fictif.
- 15 Microsoft 365 and Outlook Basics : vérifications du compte dans l'ordre (connexion, licence avec `Get-MgUserLicenseDetail`, boîte aux lettres, MFA avec vérification d'identité avant toute réinitialisation), un guide des profils Outlook, du mode Exchange mis en cache et de la reconstruction des fichiers `.ost`, un guide des boîtes aux lettres partagées (Full Access, Send As, Send on Behalf, mappage automatique), et `Get-OutlookClientInfo.ps1`.
- Intégration continue : markdownlint, vérification des liens relatifs, PSScriptAnalyzer, et analyse de chaque script par Windows PowerShell 5.1.
- Vérification hebdomadaire des liens externes vers la documentation des fabricants (`external-links.yml`), tenue à l'écart des pull requests.
- `CONTRIBUTING.md` avec les règles d'écriture, les règles des scripts et les vérifications locales.
- Formulaire d'issue **Report an error in a runbook**.
- Ce journal des modifications.

### Modifié

- Révision de publication des runbooks 01 à 05, pour que les cinq premiers suivent le modèle comme les suivants :
  - 01 Boot and BIOS / UEFI : procédure numérotée de Step 1 à 4, prérequis de suspension de BitLocker, sections de dépannage et de retour arrière ; le guide « le PC ne démarre pas » reçoit une liste de vérification.
  - 02 Windows 11 Clean Installation : commandes de vérification (UEFI, GPT, Secure Boot, activation) et une section de retour arrière qui explique pourquoi seule la sauvegarde peut annuler une installation propre.
  - 03 Software Deployment : retour arrière pour winget, les mauvaises mises à niveau (version précédente et `winget pin`) et MSI, et trois lignes de dépannage de plus.
  - 04 Network Troubleshooting : avertissement qu'une réinitialisation réseau peut effacer une configuration IP statique, sections de vérification, de dépannage et de retour arrière ; l'aide-mémoire des commandes reçoit ses badges et une capture Windows intégrée avec `pktmon`.
  - 05 Active Directory User Management : appartenances aux groupes exportées en CSV avant un départ, sections de dépannage et de retour arrière (y compris les restaurations depuis la corbeille AD).
- README : les niveaux de l'index correspondent maintenant au badge de chaque document (avec une légende), le schéma des liens est coloré par domaine, et le tableau du standard liste la section Rollback.
- `TEMPLATE.md` : bloc d'escalade facultatif et liste des travaux liés, et ce qu'il faut écrire quand une étape ne peut pas être annulée.
- Badge « Last reviewed » sur chaque document révisé pour cette version.
- 04 Network Troubleshooting : ports d'impression ajoutés à la liste des ports courants, avec des liens vers les runbooks 06 et 07 ; l'étape de la couche physique renvoie aux runbooks 08 et 09 ; la vérification des ports renvoie au runbook 10, et l'aide-mémoire reçoit des commandes Cisco switchport, trunk, err-disabled et PoE avec un lien vers le runbook 11 ; il reçoit aussi un test de port TCP et une commande pour les ports de conteneurs, avec un lien vers le runbook 12.
- 02 Windows 11 Clean Installation : la liste de vérification après installation renvoie au test de restauration et à l'Historique des fichiers.
- 05 Active Directory User Management et la liste de sécurité de l'assistance à distance (07) renvoient aux premières mesures en cas d'hameçonnage (runbook 14) ; les départs de comptes renvoient au retrait des autorisations sur les boîtes partagées (runbook 15).
- L'index du README, le schéma des liens et le formulaire de signalement d'erreur listent les runbooks 06 à 15.
- Les notes d'étude copiées (`LAN.md`, `ABC-Cybersecurity.md`, `RoadMAP.md`) sont déplacées dans [`archive/`](archive/README.fr.md), chacune avec une note qui crédite sa source. Elles ne sont plus présentées comme des runbooks originaux.

### Retiré

- Le fichier vide `Software Vulnerabilities.md`.
- Une liste de serveurs de laboratoire personnels dans les notes de plan de carrière archivées.

## [0.1.0] - 2026-10-20

### Ajouté

- Modèle de runbook (`TEMPLATE.md`) avec tableau d'en-tête, Objective, Prerequisites, Procedure, Verification, Troubleshooting et Rollback.
- 01 PC Boot Process and BIOS / UEFI, avec un arbre de décision de dépannage quand le PC ne démarre pas.
- 02 Windows 11 Clean Installation, avec une liste de vérification après installation.
- 03 Software Deployment (winget et MSI), avec `Install-StandardApps.ps1`.
- 04 Network Troubleshooting, avec un aide-mémoire des commandes Windows / Linux / Cisco IOS.
- 05 Active Directory User Management.
- README avec l'index des runbooks et le standard d'écriture.
