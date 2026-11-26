# Bureau à distance (RDP) avec authentification au niveau du réseau

[![Français](https://img.shields.io/badge/Langue-Français-3fe0a0?style=for-the-badge)](RDP.fr.md)
[![English](https://img.shields.io/badge/Language-English-2b9dff?style=for-the-badge)](RDP.md)

![Level](https://img.shields.io/badge/Level-Intermediate-ffb454?style=flat-square)
![Time](https://img.shields.io/badge/Time-15%20min-2b9dff?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Windows%2011%20Pro%20%7C%20Windows%20Server-0078D6?style=flat-square)
![Reviewed](https://img.shields.io/badge/Last%20reviewed-2026--10-555?style=flat-square)

| Élément | Contenu |
|---|---|
| **Référent** | Activer, restreindre et tester le Bureau à distance sur un poste ou un serveur Windows. |
| **Émetteur** | **bazeeza** |
| **Message** | N'ouvrir RDP qu'aux personnes et aux réseaux qui en ont besoin, avec l'authentification au niveau du réseau, et prouver que ça fonctionne. |
| **Récepteur** | Techniciens de soutien et d'administration système. |
| **Canal** | Dépôt GitHub `Bazeeza/Technical-Runbooks` |
| **Code** | Français, rédaction technique (traduction de l'original anglais) · Paramètres de Windows, PowerShell, `mstsc` |
| **Référence** | [Microsoft Learn: Enable Remote Desktop on your PC](https://learn.microsoft.com/en-us/windows-server/remote/remote-desktop-services/remotepc/remote-desktop-allow-access) · [Change the Remote Desktop listening port](https://learn.microsoft.com/en-us/windows-server/remote/remote-desktop-services/remotepc/change-listening-port) · [Test-NetConnection](https://learn.microsoft.com/en-us/powershell/module/nettcpip/test-netconnection) |

Retour à [07 Soutien à distance](README.fr.md).

---

## Objectif

Le Bureau à distance ouvre une **session Windows complète** sur un autre ordinateur, avec le compte du technicien. Contrairement à Quick Assist, personne n'a besoin d'être devant l'écran, ce qui en fait l'outil des serveurs et du travail en dehors des heures, et aussi une cible favorite des attaquants. L'état final visé : RDP activé avec **NLA**, joignable seulement depuis le réseau interne ou un VPN, et limité à des comptes nommés.

## Points clés

| Élément | Valeur |
|---|---|
| Port par défaut | **TCP 3389** (et UDP 3389 pour de meilleures performances) |
| Peut servir d'**hôte** RDP | Windows Pro, Entreprise, Éducation, Windows Server. **Windows Famille ne le peut pas**, il peut seulement se connecter à d'autres |
| Qui peut se connecter | Les membres du groupe local **Administrators** (*Administrateurs*) et de **Remote Desktop Users** (*Utilisateurs du Bureau à distance*) |
| Client | Connexion Bureau à distance (`mstsc.exe`) ou l'application Windows App |
| NLA | L'utilisateur s'authentifie **avant** la création de la session à distance |

**Pourquoi NLA est important :** sans NLA, l'ordinateur démarre un écran d'ouverture de session complet pour quiconque atteint le port 3389, avant de savoir de qui il s'agit. Avec NLA, les identifiants sont vérifiés d'abord, ce qui consomme moins de ressources sur l'hôte et réduit l'exposition aux attaques contre l'écran d'ouverture de session. Microsoft recommande de le garder activé.

## Prérequis

- [ ] Des droits d'administrateur sur l'ordinateur cible (pour modifier le réglage)
- [ ] Une édition qui peut héberger RDP (pas Windows Famille)
- [ ] La liste des comptes qui ont vraiment besoin d'accès, idéalement un **groupe de sécurité** plutôt que des utilisateurs individuels
- [ ] Un accès réseau du PC du technicien vers la cible : même réseau, ou par le **VPN** de l'organisation

> [!WARNING]
> Ne redirigez jamais le port 3389 d'Internet vers un poste. Les ports RDP exposés sont balayés et attaqués en permanence. Atteignez RDP par un VPN ou une passerelle Bureau à distance (Remote Desktop Gateway).

---

## Procédure

### Étape 1 — Activer le Bureau à distance avec NLA

**Paramètres → Système → Bureau à distance** → activez **Bureau à distance** → **Confirmer**. Développez le réglage et vérifiez que **Exiger que les appareils utilisent l'authentification au niveau du réseau pour se connecter** est coché.

La même chose dans un PowerShell élevé (utile sur de nombreux PC ou sur Server Core) :

```powershell
$ts = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
Set-ItemProperty -Path $ts -Name fDenyTSConnections -Value 0
Set-ItemProperty -Path "$ts\WinStations\RDP-Tcp" -Name UserAuthentication -Value 1
Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'
```

| Ligne | Ce qu'elle fait |
|---|---|
| `fDenyTSConnections = 0` | Autorise les connexions Bureau à distance entrantes (1 = refusées) |
| `UserAuthentication = 1` | Exige l'authentification au niveau du réseau |
| `Enable-NetFirewallRule` | Ouvre les règles intégrées du Pare-feu Windows pour RDP |

> [!NOTE]
> `-DisplayGroup 'Remote Desktop'` ne fonctionne que sur un Windows en anglais. Sur un système en français ou dans une autre langue, utilisez plutôt le nom de groupe indépendant de la langue : `Enable-NetFirewallRule -Group '@FirewallAPI.dll,-28752'`. Il en va de même pour l'étape 3 et pour le retour arrière.

**Résultat attendu :** la page Paramètres montre le Bureau à distance **Activé** et NLA coché.

### Étape 2 — Autoriser seulement les bons comptes

Dans **Paramètres → Système → Bureau à distance → Utilisateurs du Bureau à distance**, ajoutez le compte ou le groupe. Ou :

```powershell
Add-LocalGroupMember -Group 'Remote Desktop Users' -Member 'EXAMPLE\Helpdesk-RDP'
Get-LocalGroupMember -Group 'Remote Desktop Users'
```

**Pourquoi un groupe :** quand un technicien arrive dans l'équipe ou la quitte, vous modifiez un seul groupe AD au lieu de chaque ordinateur.

### Étape 3 — Restreindre la règle de pare-feu aux adresses internes

La règle intégrée accepte les connexions de n'importe quelle adresse sur le profil choisi. Limitez-la au sous-réseau des TI ou à la plage du VPN :

```powershell
Get-NetFirewallRule -DisplayGroup 'Remote Desktop' |
    Set-NetFirewallRule -RemoteAddress '192.0.2.0/24'
```

Remplacez `192.0.2.0/24` par le vrai sous-réseau de gestion ou du VPN. Dans un domaine, ce réglage se fait habituellement une seule fois par stratégie de groupe plutôt que sur chaque PC.

### Étape 4 — Tester depuis le PC du technicien

```powershell
Test-NetConnection pc-0001.corp.example.com -Port 3389
mstsc /v:pc-0001.corp.example.com
```

**Résultat attendu :** `TcpTestSucceeded : True`, puis la demande d'identifiants **avant** l'apparition du bureau à distance (c'est NLA qui fonctionne).

### Étape 5 — Fermer la session correctement

Utilisez **Démarrer → icône de l'utilisateur → Se déconnecter** dans la session à distance. Fermer la fenêtre avec le **X** ne fait que *déconnecter* : la session continue de tourner sur l'hôte avec les applications ouvertes, et elle occupe une licence ou une place sur un serveur.

---

## Vérification

- [ ] `Test-NetConnection <host> -Port 3389` réussit depuis une adresse autorisée et échoue depuis un autre réseau
- [ ] La demande d'identifiants apparaît avant le bureau à distance (NLA)
- [ ] `Get-LocalGroupMember 'Remote Desktop Users'` ne liste que les comptes prévus
- [ ] La connexion et la déconnexion sont notées dans le billet

## Dépannage

| Symptôme | Cause probable | Correction |
|---|---|---|
| « Remote Desktop can't connect to the remote computer » (*le Bureau à distance ne peut pas se connecter à l'ordinateur distant*) | RDP désactivé, PC éteint ou en veille, pare-feu qui bloque 3389, mauvais nom | `Test-NetConnection -Port 3389`, puis vérifier l'étape 1 et la règle de pare-feu |
| Aucune page Bureau à distance dans Paramètres, ou impossible de l'activer | Édition Windows Famille | Mettre à niveau l'édition, ou utiliser Quick Assist |
| « The connection was denied because the user account is not authorized » (*connexion refusée, compte non autorisé*) | Compte absent de **Remote Desktop Users** ou d'Administrators | L'ajouter (étape 2) |
| Un ancien client ne peut plus se connecter après l'activation de NLA | Le client ne prend pas en charge NLA | Mettre le client à jour ; ne pas désactiver NLA de façon permanente |
| Le nom ne se résout pas, l'IP fonctionne | Problème DNS | Voir [04 Dépannage réseau](../04-Network-Troubleshooting/README.fr.md), étape 5 |
| Ça fonctionne sur le réseau local, pas depuis la maison | Pas de VPN, ou la règle de pare-feu est limitée à la plage du réseau local | Se connecter d'abord au VPN ; ajouter la plage du VPN à la règle si c'est approuvé |

## Retour arrière

Désactivez le **Bureau à distance** dans Paramètres, ou :

```powershell
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 1
Disable-NetFirewallRule -DisplayGroup 'Remote Desktop'
```

---

<sub>Écrit par bazeeza · Vous avez trouvé une erreur ? <a href="https://github.com/Bazeeza/Technical-Runbooks/issues/new?template=runbook-error.yml">Signalez-la ici</a>.</sub>
