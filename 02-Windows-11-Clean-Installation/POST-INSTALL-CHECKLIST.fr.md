# Liste de vérification après l'installation de Windows 11

[![Français](https://img.shields.io/badge/Langue-Français-3fe0a0?style=for-the-badge)](POST-INSTALL-CHECKLIST.fr.md)
[![English](https://img.shields.io/badge/Language-English-2b9dff?style=for-the-badge)](POST-INSTALL-CHECKLIST.md)

![Level](https://img.shields.io/badge/Level-Beginner-3fe0a0?style=flat-square)
![Time](https://img.shields.io/badge/Time-30%E2%80%9345%20min-2b9dff?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Windows%2011-0078D6?style=flat-square)
![Reviewed](https://img.shields.io/badge/Last%20reviewed-2026--11-555?style=flat-square)

| Élément | Contenu |
|---|---|
| **Référent** | Vérifications et réglages à faire après l'installation de Windows 11, avant de remettre le poste à un utilisateur. |
| **Émetteur** | **bazeeza** |
| **Message** | Livrer un poste à jour, sécurisé, identifié et vérifié, de la même façon à chaque fois. |
| **Récepteur** | Techniciens de soutien. |
| **Canal** | Dépôt GitHub `Bazeeza/Technical-Runbooks` |
| **Code** | Français, rédaction technique (traduction de l'original anglais) |
| **Référence** | [Windows Update](https://learn.microsoft.com/en-us/windows/deployment/update/) · [BitLocker](https://learn.microsoft.com/en-us/windows/security/operating-system-security/data-protection/bitlocker/) · [Join a computer to a domain](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/deploy/join-a-computer-to-a-domain) |

---

## Objectif

Une liste de vérification retire le « j'ai oublié » du travail : chaque poste quitte l'atelier dans le même état connu. Copiez cette liste dans le billet et cochez chaque élément.

> Toutes les commandes se lancent dans **PowerShell en tant qu'administrateur**, sauf indication contraire.

---

## 1. Mises à jour et pilotes

- [ ] **Windows Update** : Paramètres → Windows Update → *Rechercher des mises à jour*. Recommencer jusqu'à ce qu'il ne reste rien (plusieurs redémarrages sont normaux).
- [ ] **Pilotes et firmware du fabricant** avec l'outil du fabricant : Dell Command | Update, Lenovo System Update / Commercial Vantage, HP Image Assistant / Support Assistant.
- [ ] **Gestionnaire de périphériques** (`devmgmt.msc`) : aucun appareil avec un triangle jaune d'avertissement.

```powershell
# List devices with a problem (empty result = all good)
Get-PnpDevice | Where-Object Status -ne 'OK' | Select-Object Class, FriendlyName, Status
```

Le commentaire signifie : lister les appareils qui ont un problème (résultat vide = tout va bien).

## 2. Activation

- [ ] Paramètres → Système → Activation affiche **Windows est activé**.

```powershell
slmgr /xpr    # opens a window showing the activation status
```

Le commentaire signifie : ouvre une fenêtre qui affiche l'état de l'activation.

## 3. Identité du poste

- [ ] Renommer le PC selon la convention de nommage de l'organisation (exemple : `MTL-LT-0042` = site, type, numéro d'inventaire).

```powershell
Rename-Computer -NewName "MTL-LT-0042" -Restart
```

- [ ] **Jonction au domaine** (Active Directory local, édition Professionnel ou Entreprise), après le renommage :

```powershell
Add-Computer -DomainName "corp.example.com" -OUPath "OU=Workstations,DC=corp,DC=example,DC=com" -Credential (Get-Credential) -Restart
```

- [ ] Ou **Entra ID / Intune** : Paramètres → Comptes → Accès Professionnel ou Scolaire → Connecter.
- [ ] Noter le numéro de série et l'étiquette d'inventaire dans l'inventaire (GLPI ou équivalent) :

```powershell
Get-CimInstance Win32_BIOS | Select-Object SerialNumber
```

## 4. Sécurité

- [ ] **Microsoft Defender** (ou l'antivirus/EDR de l'organisation) actif et à jour : Sécurité Windows → Protection contre les virus et menaces.
- [ ] **Pare-feu** activé pour tous les profils :

```powershell
Get-NetFirewallProfile | Select-Object Name, Enabled   # all must be True
```

Le commentaire signifie : tous doivent être à `True`.

- [ ] **BitLocker** activé sur le lecteur système, clé de récupération enregistrée dans AD / Entra ID (jamais seulement sur le PC lui-même) :

```powershell
manage-bde -status C:
```

- [ ] Le compte d'usage quotidien est un **utilisateur standard**, pas un administrateur local (principe du moindre privilège).
- [ ] Retirer les logiciels préinstallés non voulus (antivirus d'essai, jeux).

## 5. Applications et configuration de l'utilisateur

- [ ] Installer les applications standard : voir le [runbook 03 — Déploiement de logiciels](../03-Software-Deployment/README.fr.md).
- [ ] Imprimantes, lecteurs réseau et VPN selon le service de l'utilisateur (imprimantes déployées par stratégie de groupe : voir le [runbook 06](../06-Printer-Troubleshooting/GPO-DEPLOYMENT.md)).
- [ ] Outlook ouvre la boîte aux lettres de l'utilisateur et la MFA est enregistrée : voir le [runbook 15 — Microsoft 365 and Outlook Basics](../15-Microsoft-365-Outlook-Basics/README.md).
- [ ] Restaurer les données de l'utilisateur depuis la sauvegarde, puis laisser l'utilisateur confirmer que ses fichiers sont là (pour prouver la restauration fichier par fichier, voir le [runbook 13 — Backup and Restore](../13-Backup-and-Restore/README.md#step-5--test-the-restore-mandatory)).
- [ ] Activer la sauvegarde propre au poste (Historique des fichiers ou l'outil du site) : voir [Windows backups](../13-Backup-and-Restore/WINDOWS-BACKUP.md#option-a--file-history-workstation).

## 6. Vérification finale

- [ ] Redémarrer une dernière fois : le PC démarre sans erreur
- [ ] Réseau, Internet et ressources internes accessibles (voir le [runbook 04](../04-Network-Troubleshooting/README.fr.md))
- [ ] Son, caméra, Wi-Fi, Bluetooth et station d'accueil testés
- [ ] Billet mis à jour avec le travail fait, puis fermé avec la confirmation de l'utilisateur

---

<sub>Écrit par bazeeza · Vous avez trouvé une erreur ? <a href="https://github.com/Bazeeza/Technical-Runbooks/issues/new?template=runbook-error.yml">Signalez-la ici</a>.</sub>
