# Gestion des comptes d'utilisateurs Active Directory

[![Français](https://img.shields.io/badge/Langue-Français-3fe0a0?style=for-the-badge)](README.fr.md)
[![English](https://img.shields.io/badge/Language-English-2b9dff?style=for-the-badge)](README.md)

![Level](https://img.shields.io/badge/Level-Beginner%20to%20Intermediate-ffb454?style=flat-square)
![Time](https://img.shields.io/badge/Time-5%E2%80%9320%20min-2b9dff?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Windows%20Server%20AD%20DS-0078D6?style=flat-square)
![Reviewed](https://img.shields.io/badge/Last%20reviewed-2026--11-555?style=flat-square)

| Élément | Contenu |
|---|---|
| **Référent** | Les demandes de soutien les plus courantes sur les comptes Active Directory : compte verrouillé, réinitialisation de mot de passe, nouvel employé, départ. |
| **Émetteur** | **bazeeza** |
| **Message** | Traiter chaque demande rapidement avec PowerShell ou la console graphique, **après** avoir vérifié l'identité de l'appelant, et laisser une trace dans le billet. |
| **Récepteur** | Techniciens de soutien qui ont des droits délégués sur les comptes d'utilisateurs. |
| **Canal** | Dépôt GitHub `Bazeeza/Technical-Runbooks` |
| **Code** | Français, rédaction technique (traduction de l'original anglais) · PowerShell (module ActiveDirectory) |
| **Référence** | [ActiveDirectory PowerShell module](https://learn.microsoft.com/en-us/powershell/module/activedirectory/) · [Event 4740: account locked out](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-10/security/threat-protection/auditing/event-4740) · [Active Directory Recycle Bin](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/get-started/adac/active-directory-recycle-bin) |

---

## Objectif

« Je n'arrive pas à me connecter » est l'appel le plus fréquent au soutien TI. Le résoudre prend quelques minutes, mais **réinitialiser le mot de passe de la mauvaise personne donne le compte à un attaquant** : l'ingénierie sociale par téléphone est une attaque classique. Ce runbook fait de la vérification de l'identité la première étape obligatoire, puis donne les commandes exactes pour chaque demande.

## Prérequis

- [ ] Un compte avec des **droits délégués** sur l'OU des utilisateurs (pas un compte Domain Admin pour les tâches quotidiennes)
- [ ] Les outils **RSAT: Active Directory** installés sur le PC du technicien :

```powershell
# Windows 10/11, administrator PowerShell
Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
Import-Module ActiveDirectory
```

Le commentaire signifie : Windows 10/11, PowerShell en administrateur.

- [ ] La procédure de vérification d'identité et la politique de mots de passe de l'organisation

> Dans les exemples, l'utilisateur est `jdoe` et le domaine est `corp.example.com`. Remplacez-les par les vraies valeurs.

---

## Étape 0 — Vérifier l'identité de l'appelant (obligatoire)

Avant **toute** modification d'un compte :

1. **Ne jamais se fier seulement à l'afficheur ou au nom donné.**
2. Vérifier avec la méthode définie par l'organisation, par exemple :
   - rappeler au numéro inscrit dans l'annuaire, pas au numéro donné par l'appelant ;
   - confirmation par le gestionnaire de l'employé ;
   - en personne, avec une carte d'identité avec photo ;
   - un code envoyé à une méthode MFA déjà enregistrée.
3. Refuser et faire une escalade à la sécurité si l'appelant met de la pression, ne peut pas être vérifié ou demande une exception.
4. Écrire dans le billet **comment** l'identité a été vérifiée.

---

## Cas 1 — Compte verrouillé

### Vérifier l'état du compte

```powershell
Get-ADUser jdoe -Properties LockedOut, Enabled, LastLogonDate, PasswordLastSet, PasswordExpired, BadLogonCount |
    Select-Object Name, Enabled, LockedOut, PasswordExpired, PasswordLastSet, LastLogonDate, BadLogonCount
```

| Valeur | Signification |
|---|---|
| `LockedOut : True` | Trop de mauvais mots de passe : déverrouiller (ci-dessous) |
| `Enabled : False` | Compte **désactivé** volontairement (départ, congé) : ne pas le réactiver sans approbation |
| `PasswordExpired : True` | Le mot de passe doit être changé, pas seulement déverrouillé |

### Déverrouiller

```powershell
Unlock-ADAccount -Identity jdoe
```

### Si le compte se verrouille de nouveau : trouver la source

Les verrouillages répétés viennent le plus souvent d'un **ancien mot de passe enregistré quelque part** : application de courriel du téléphone, lecteur réseau mappé, profil Wi-Fi, tâche planifiée, deuxième PC. Le contrôleur de domaine qui détient le rôle d'*émulateur PDC* (*PDC emulator*) enregistre l'événement **4740** avec le nom de l'ordinateur source.

```powershell
$pdc = (Get-ADDomain).PDCEmulator
Get-WinEvent -ComputerName $pdc -FilterHashtable @{ LogName = 'Security'; Id = 4740 } -MaxEvents 50 |
    Where-Object { $_.Properties[0].Value -eq 'jdoe' } |
    Select-Object TimeCreated, @{ n = 'SourceComputer'; e = { $_.Properties[1].Value } }
```

Ensuite, retirer ou mettre à jour le mot de passe enregistré sur l'appareil source.

## Cas 2 — Réinitialisation du mot de passe

Seulement après l'étape 0 :

```powershell
Set-ADAccountPassword -Identity jdoe -Reset -NewPassword (Read-Host -AsSecureString 'Temporary password')
Set-ADUser -Identity jdoe -ChangePasswordAtLogon $true
Unlock-ADAccount -Identity jdoe
```

- `Read-Host -AsSecureString` garde le mot de passe hors de l'écran, de l'historique des commandes et des journaux.
- Le mot de passe temporaire respecte la politique, est **unique** et est transmis par un canal sécurisé (jamais par courriel vers le compte qu'on réinitialise).
- `ChangePasswordAtLogon` garantit que seul l'utilisateur connaît le mot de passe final.

> [!WARNING]
> Si la réinitialisation est nécessaire parce que l'utilisateur a tapé son mot de passe sur une page d'hameçonnage, une réinitialisation seule ne suffit pas : pour un compte synchronisé avec Microsoft 365, Microsoft recommande de le réinitialiser **deux fois** dans Active Directory, puis de révoquer les sessions de l'utilisateur et de vérifier les règles de la boîte aux lettres. Suivez la [liste C du runbook 14](../14-Phishing-Report-and-First-Response/FIRST-RESPONSE-CHECKLIST.fr.md#liste-c--a-tapé-un-mot-de-passe-ou-approuvé-une-demande-mfa-inattendue).

## Cas 3 — Nouvel employé

```powershell
$params = @{
    Name                  = 'Jane Doe'
    GivenName             = 'Jane'
    Surname               = 'Doe'
    SamAccountName        = 'jdoe'
    UserPrincipalName     = 'jdoe@corp.example.com'
    Path                  = 'OU=Users,OU=Montreal,DC=corp,DC=example,DC=com'
    Title                 = 'Accountant'
    Department            = 'Finance'
    AccountPassword       = (Read-Host -AsSecureString 'Temporary password')
    ChangePasswordAtLogon = $true
    Enabled               = $true
}
New-ADUser @params

# Access is given through groups, never directly to a user
Add-ADGroupMember -Identity 'GRP-Finance' -Members jdoe
Get-ADPrincipalGroupMembership jdoe | Select-Object Name
```

Le commentaire signifie : les accès sont donnés par des groupes, jamais directement à un utilisateur.

- Créer le compte **seulement** à partir d'une demande approuvée (RH ou gestionnaire).
- Utiliser des groupes par rôle (`GRP-Finance`), pour que les accès soient cohérents et faciles à retirer.
- Accorder le minimum nécessaire : aucun groupe d'administrateurs « au cas où ».

## Cas 4 — Départ d'un employé

Désactiver d'abord, supprimer plus tard : un compte désactivé peut être rétabli au besoin, un compte supprimé est beaucoup plus difficile à récupérer.

```powershell
$date = Get-Date -Format 'yyyy-MM-dd'
Disable-ADAccount -Identity jdoe
Set-ADUser -Identity jdoe -Description "Disabled $date - ticket #12345"

# Record the group memberships first: this file is what makes a rollback possible
New-Item -ItemType Directory -Force C:\Temp | Out-Null
Get-ADPrincipalGroupMembership jdoe | Select-Object Name, DistinguishedName |
    Export-Csv "C:\Temp\jdoe-groups-$date.csv" -NoTypeInformation

# Then remove them (except Domain Users) and attach the CSV file to the ticket
Get-ADPrincipalGroupMembership jdoe | Where-Object Name -ne 'Domain Users' |
    ForEach-Object { Remove-ADGroupMember -Identity $_ -Members jdoe -Confirm:$false }

Move-ADObject -Identity (Get-ADUser jdoe).DistinguishedName -TargetPath 'OU=Disabled,DC=corp,DC=example,DC=com'
```

Les commentaires signifient, dans l'ordre : enregistrer d'abord les appartenances aux groupes, car c'est ce fichier qui rend un retour arrière possible ; ensuite les retirer (sauf Domain Users) et joindre le fichier CSV au billet.

Ensuite, suivre le processus de l'organisation : boîte aux lettres, fichiers, appareils rendus, suppression après la période de conservation. Retirer le jour même les permissions de l'utilisateur sur les boîtes aux lettres partagées ([runbook 15](../15-Microsoft-365-Outlook-Basics/SHARED-MAILBOXES-AND-PERMISSIONS.fr.md#étape-4--retirer-laccès-quand-il-nest-plus-nécessaire)).

---

## Solution graphique (ADUC)

Tout ce qui précède peut aussi se faire dans **Active Directory Users and Computers** (*Utilisateurs et ordinateurs Active Directory*, `dsa.msc`) : clic droit sur l'utilisateur → **Reset Password** (*Réinitialiser le mot de passe*, avec *User must change password at next logon* et *Unlock the user's account* cochés), **Disable Account** (*Désactiver le compte*), **Add to a group** (*Ajouter à un groupe*), **Move** (*Déplacer*). PowerShell est plus rapide, reproductible, et ses commandes exactes peuvent être collées dans le billet.

## Vérification

- [ ] L'utilisateur se connecte avec succès (ou le compte de l'employé parti ne peut plus se connecter)
- [ ] `Get-ADUser jdoe -Properties LockedOut, Enabled` affiche l'état attendu
- [ ] Le billet indique : méthode de vérification de l'identité, actions effectuées, groupes modifiés

## Dépannage

| Symptôme | Cause probable | Correction |
|---|---|---|
| `Get-ADUser` n'est pas reconnu | Outils RSAT absents ou module non chargé | Installer la fonctionnalité RSAT (prérequis), puis `Import-Module ActiveDirectory` |
| `Access is denied` à la réinitialisation ou au déverrouillage | Le compte du technicien n'a pas de droit délégué sur cette OU | Faire une escalade aux administrateurs AD ; ne pas utiliser un compte Domain Admin pour contourner le problème |
| Le compte se verrouille de nouveau quelques minutes après le déverrouillage | Un ancien mot de passe enregistré sur un téléphone, un lecteur mappé ou un autre PC | Trouver l'ordinateur source avec l'événement 4740 (cas 1), y effacer le mot de passe enregistré |
| Le nouveau mot de passe est refusé | Il ne respecte pas la politique de mots de passe (longueur, complexité, historique) | `Get-ADDefaultDomainPasswordPolicy` affiche les règles ; choisir un mot de passe temporaire conforme |
| L'utilisateur ne peut toujours pas se connecter sur un portable hors du bureau | Le PC n'a pas contacté de contrôleur de domaine depuis la réinitialisation | Brancher le PC au réseau du bureau ou au RPV (VPN), puis se connecter avec le nouveau mot de passe |
| Une modification n'apparaît pas sur un autre contrôleur de domaine | La réplication entre contrôleurs de domaine prend du temps | Attendre, ou lancer la commande sur le même serveur avec `-Server <DC>` |

## Retour arrière

| Action | Comment l'annuler |
|---|---|
| Compte désactivé par erreur | `Enable-ADAccount -Identity jdoe`, puis effacer la description |
| Groupes retirés lors d'un départ | Les rajouter à partir du fichier CSV enregistré au cas 4 : `Import-Csv <file> \| Where-Object Name -ne 'Domain Users' \| ForEach-Object { Add-ADGroupMember -Identity $_.DistinguishedName -Members jdoe }` |
| Compte déplacé dans l'OU *Disabled* | `Move-ADObject` pour le remettre dans l'OU d'origine (notée dans le billet) |
| Compte supprimé | Possible seulement si la **corbeille AD** (*AD Recycle Bin*) était activée **avant** la suppression ; le compte restauré retrouve ses groupes : `Get-ADObject -Filter 'SamAccountName -eq "jdoe"' -IncludeDeletedObjects \| Restore-ADObject` ; sinon, faire une escalade (restauration faisant autorité à partir d'une sauvegarde) |
| Mot de passe réinitialisé | Impossible à annuler : l'ancien mot de passe n'est pas conservé. Donner à l'utilisateur un nouveau mot de passe temporaire par un canal sécurisé |

## Recherches utiles

```powershell
Search-ADAccount -LockedOut | Select-Object Name, SamAccountName               # all locked accounts
Search-ADAccount -AccountInactive -TimeSpan 90.00:00:00 -UsersOnly |           # inactive for 90+ days
    Select-Object Name, LastLogonDate
Search-ADAccount -PasswordNeverExpires -UsersOnly | Select-Object Name          # policy exceptions to review
```

Les commentaires signifient, dans l'ordre : tous les comptes verrouillés ; inactifs depuis 90 jours ou plus ; exceptions à la politique à revoir.

---

<sub>Écrit par bazeeza · Vous avez trouvé une erreur ? <a href="https://github.com/Bazeeza/Technical-Runbooks/issues/new?template=runbook-error.yml">Signalez-la ici</a>.</sub>
