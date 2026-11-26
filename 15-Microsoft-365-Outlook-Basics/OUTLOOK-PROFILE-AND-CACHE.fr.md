# Profils Outlook et mode Exchange mis en cache

[![Français](https://img.shields.io/badge/Langue-Français-3fe0a0?style=for-the-badge)](OUTLOOK-PROFILE-AND-CACHE.fr.md)
[![English](https://img.shields.io/badge/Language-English-2b9dff?style=for-the-badge)](OUTLOOK-PROFILE-AND-CACHE.md)

![Level](https://img.shields.io/badge/Level-Beginner-3fe0a0?style=flat-square)
![Time](https://img.shields.io/badge/Time-15%E2%80%9345%20min-2b9dff?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Classic%20Outlook%20for%20Windows-0078D6?style=flat-square)
![Reviewed](https://img.shields.io/badge/Last%20reviewed-2026--11-555?style=flat-square)

| Élément | Contenu |
|---|---|
| **Référent** | Le côté local d'Outlook classique pour Windows : le profil qui contient les comptes, et le fichier de données hors connexion (`.ost`) tenu par le mode Exchange mis en cache (Cached Exchange Mode). |
| **Émetteur** | **bazeeza** |
| **Message** | Distinguer un problème du client d'un problème du compte, démarrer en mode sans échec, créer un profil propre sans supprimer l'ancien, régler le mode Exchange mis en cache et la période hors connexion, et reconstruire un fichier `.ost` en toute sécurité. |
| **Récepteur** | Techniciens de soutien TI. |
| **Canal** | Dépôt GitHub `Bazeeza/Technical-Runbooks` |
| **Code** | Français, rédaction technique (traduction de l'original anglais) · Windows PowerShell 5.1 |
| **Référence** | [Microsoft Learn: Plan and configure Cached Exchange Mode](https://learn.microsoft.com/en-us/microsoft-365-apps/outlook/configuration/cached-exchange-mode) · [Microsoft Support: Turn on Cached Exchange Mode](https://support.microsoft.com/office/7885af08-9a60-4ec3-850a-e221c1ed0c1c) · [Microsoft Support: Create an Outlook profile](https://support.microsoft.com/office/f544c1ba-3352-4b3b-be0b-8d42a540459d) · [Microsoft Support: Change or update e-mail account settings in Outlook for Windows](https://support.microsoft.com/en-us/outlook/change-or-update-email-account-settings-in-outlook-for-windows) |

Retour à [15 Notions de base de Microsoft 365 et d'Outlook](README.fr.md).

---

## Outlook classique ou nouvel Outlook ?

Windows 11 peut avoir deux applications Outlook différentes. Demandez à l'utilisateur laquelle il ouvre, ou lancez [`Get-OutlookClientInfo.ps1`](Get-OutlookClientInfo.ps1).

| | Outlook classique | Nouvel Outlook pour Windows |
|---|---|---|
| Fourni avec | Microsoft 365 Apps (Word, Excel...) | Windows 11, ou le Microsoft Store |
| Nom du processus | `OUTLOOK.EXE` | `olk.exe` |
| Profils | Oui, gérés dans ce guide | Non : les comptes s'ajoutent dans **Settings** › **Accounts** |
| Données hors connexion | Fichier `.ost` (mode Exchange mis en cache) | Gérées par l'application |
| Compléments | Compléments COM et compléments web | Compléments web seulement |

Le reste de ce guide s'applique à **Outlook classique**.

## Étape 1 — Vérifier que le problème vient du client

Avant de modifier quoi que ce soit sur le PC, ouvrez **Outlook sur le web** avec le même compte dans un navigateur.

| Outlook sur le web | Conclusion | Suite |
|---|---|---|
| Même problème (courriels absents, envoi impossible, erreur) | Le **compte ou la boîte aux lettres** | [Runbook 15, vérifications du compte](README.fr.md#étape-1--vérifier-le-compte-et-sa-licence) |
| Fonctionne normalement | Le **client** sur ce PC | Continuer ci-dessous |

**Résultat attendu :** vous savez s'il faut travailler sur le PC ou sur le compte.

## Étape 2 — Démarrer en mode sans échec

Le mode sans échec démarre Outlook sans compléments et sans les personnalisations du volet de lecture. Fermez Outlook, puis lancez :

```powershell
outlook.exe /safe
```

Le même commutateur fonctionne depuis **Win + R**. Si Outlook fonctionne en mode sans échec, désactivez les compléments un par un : **File** › **Options** › **Add-ins** › **Manage: COM Add-ins** › **Go**.

**Résultat attendu :** Outlook démarre, et vous savez si un complément est en cause.

## Étape 3 — Créer un nouveau profil (garder l'ancien)

Un profil contient les comptes et pointe vers le fichier `.ost`. Un profil endommagé provoque des demandes de mot de passe sans fin, une boucle à « Loading profile » ou des dossiers qui ne se mettent jamais à jour. Un **nouveau** profil est plus rapide et plus sûr que la réparation de l'ancien, et l'ancien reste disponible si quelque chose a été oublié.

1. Fermez Outlook.
2. Ouvrez la liste des profils par l'un de ces moyens :
   - **Control Panel** (Panneau de configuration ; affichage : **Large icons**) › **Mail (Microsoft Outlook)** › **Show Profiles**
   - `outlook.exe /profiles`, puis **Options**
   - Dans Outlook : **File** › **Account Settings** › **Manage Profiles** › **Show Profiles**
3. Sélectionnez **Add**, nommez le profil avec la date (par exemple `Outlook-2026-11`), sélectionnez **OK**.
4. Entrez l'adresse courriel de l'utilisateur et laissez la découverte automatique (Autodiscover) configurer le compte. L'utilisateur se connecte avec son mot de passe et la MFA.
5. Sous **When starting Microsoft Outlook, use this profile**, choisissez **Always use this profile** et sélectionnez le nouveau (ou **Prompt for a profile to be used** pendant vos tests).
6. Démarrez Outlook et attendez la première synchronisation.

Les boîtes aux lettres partagées avec Full Access réapparaissent d'elles-mêmes (mappage automatique) après quelques minutes ; voir [Boîtes aux lettres partagées et permissions](SHARED-MAILBOXES-AND-PERMISSIONS.fr.md).

**Résultat attendu :** Outlook s'ouvre avec le nouveau profil, le courrier et le calendrier sont à jour. Ne retirez l'ancien profil qu'après que l'utilisateur a confirmé que rien ne manque (signatures, règles, fichiers PST locaux).

> [!WARNING]
> Avant de retirer un ancien profil, vérifiez la présence de **fichiers PST** (`Get-OutlookClientInfo.ps1` les liste). Un fichier PST n'existe que sur ce PC : il n'est pas sur le serveur et n'est pas reconstruit avec le profil.

## Étape 4 — Régler le mode Exchange mis en cache et la période hors connexion

Le mode Exchange mis en cache garde une copie de la boîte aux lettres dans un fichier `.ost` sur le PC, pour qu'Outlook reste rapide et continue de fonctionner hors connexion. Microsoft le recommande pour les comptes Microsoft 365.

1. **File** › **Account Settings** › **Account Settings**.
2. Sélectionnez le compte Microsoft 365 › **Change**.
3. Sous **Offline Settings**, cochez **Use Cached Exchange Mode** (dans certaines versions : **Use Cached Exchange Mode to download email to an Outlook data file**).
4. Réglez le curseur de la quantité de courrier à garder hors connexion. Par défaut, Outlook garde **12 mois**. Le courrier plus ancien reste sur le serveur et s'affiche avec **Click here to view more on Microsoft Exchange** à la fin d'un dossier.
5. Quittez et redémarrez Outlook.

| Situation | Réglage |
|---|---|
| Portable ou poste de bureau normal | Mode mis en cache, 12 mois par défaut |
| Petit disque, ou grosse boîte aux lettres | Mode mis en cache, période plus courte (par exemple 3 ou 6 mois) |
| PC kiosque partagé par de nombreux utilisateurs, ou données qui ne doivent pas être stockées localement | Mode en ligne (Online Mode, mode mis en cache désactivé), comme le décrit Microsoft |

**Résultat attendu :** après le redémarrage, la barre d'état affiche **Connected to: Microsoft Exchange** et **All folders are up to date** une fois la synchronisation terminée.

## Étape 5 — Reconstruire le fichier de données hors connexion

Le fichier `.ost` n'est qu'une **copie** de la boîte aux lettres : Outlook peut la télécharger de nouveau. Reconstruisez-le quand un dossier reste périmé, que le fichier est endommagé ou qu'il est devenu trop gros.

```powershell
# 1. Close Outlook and check that it is closed
Get-Process -Name OUTLOOK -ErrorAction SilentlyContinue

# 2. List the data files and their size
Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Outlook" -Filter *.ost | Select-Object Name, @{n='SizeGB';e={[math]::Round($_.Length/1GB,2)}}, LastWriteTime

# 3. Rename it (do not delete it yet)
Rename-Item "$env:LOCALAPPDATA\Microsoft\Outlook\user@contoso.com.ost" "user@contoso.com.ost.old"
```

Les commentaires signifient, dans l'ordre : fermer Outlook et vérifier qu'il est fermé ; lister les fichiers de données et leur taille ; le renommer (ne pas le supprimer tout de suite).

Démarrez Outlook : il crée un nouveau `.ost` et télécharge de nouveau la boîte aux lettres. Cela prend de quelques minutes à quelques heures selon la taille et la connexion : planifiez-le avec l'utilisateur. Supprimez le fichier `.old` après quelques jours, une fois que tout est confirmé.

> [!NOTE]
> Microsoft indique que les fichiers `.ost` sont **de 50 à 80 pour cent plus gros** que la taille de la boîte aux lettres rapportée par Exchange, et que leur taille maximale par défaut est de **50 Go**. Vérifiez l'espace disque libre avant une reconstruction.

**Résultat attendu :** un nouveau fichier `.ost`, les dossiers à jour et le courrier de l'utilisateur visible dans Outlook classique.

---

## Dépannage

| Symptôme | Cause probable | Correction |
|---|---|---|
| Outlook reste sur « Loading profile » | Profil endommagé, ou un complément | `outlook.exe /safe`, puis un nouveau profil (étape 3) |
| Demande de mot de passe qui revient sans cesse | Anciens identifiants enregistrés, profil endommagé, ou MFA non terminée | Retirer les entrées Outlook dans **Credential Manager** › **Windows Credentials** (Gestionnaire d'identification), se reconnecter ; nouveau profil si cela persiste |
| Un dossier n'est pas mis à jour | `.ost` endommagé | Reconstruire le `.ost` (étape 5) |
| Anciens courriels « absents » | Le mode Exchange mis en cache ne garde hors connexion que la période choisie | **Click here to view more on Microsoft Exchange**, ou une période plus longue sur le curseur |
| Outlook très lent, disque presque plein | `.ost` proche de sa limite | Période hors connexion plus courte, archivage, libérer de l'espace disque |
| Le courrier fonctionne sur le web mais pas dans Outlook | Problème du client | Étapes 2 à 5 |
| Le courrier ne fonctionne pas non plus sur le web | Problème de compte, de licence ou de boîte aux lettres | [Runbook 15, vérifications du compte](README.fr.md#étape-1--vérifier-le-compte-et-sa-licence) |

## Retour arrière

Sélectionnez de nouveau l'ancien profil dans **Mail (Microsoft Outlook)** › **Show Profiles** › **Always use this profile**. Pour revenir à l'ancien fichier hors connexion, fermez Outlook, renommez le nouveau `.ost` et retirez `.old` du nom du précédent.

---

<sub>Écrit par bazeeza · Vous avez trouvé une erreur ? <a href="https://github.com/Bazeeza/Technical-Runbooks/issues/new?template=runbook-error.yml">Signalez-la ici</a>.</sub>
