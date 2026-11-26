# Lire le rapport de réseau sans fil de Windows

[![Français](https://img.shields.io/badge/Langue-Français-3fe0a0?style=for-the-badge)](WLAN-REPORT.fr.md)
[![English](https://img.shields.io/badge/Language-English-2b9dff?style=for-the-badge)](WLAN-REPORT.md)

![Level](https://img.shields.io/badge/Level-Intermediate-ffb454?style=flat-square)
![Time](https://img.shields.io/badge/Time-10%20min-2b9dff?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Windows%2011-0078D6?style=flat-square)
![Reviewed](https://img.shields.io/badge/Last%20reviewed-2026--10-555?style=flat-square)

| Élément | Contenu |
|---|---|
| **Référent** | Générer et lire le rapport HTML de réseau sans fil intégré à Windows. |
| **Émetteur** | **bazeeza** |
| **Message** | Transformer « le Wi-Fi se coupe parfois » en déconnexions datées avec leur raison, avant d'escalader. |
| **Récepteur** | Techniciens de soutien TI, techniciens réseau, étudiants en informatique. |
| **Canal** | Dépôt GitHub `Bazeeza/Technical-Runbooks` |
| **Code** | Français, rédaction technique (traduction de l'original anglais) · `netsh wlan show wlanreport` |
| **Référence** | [Microsoft Support: analyze the wireless network report](https://support.microsoft.com/en-us/help/4000462) · [Microsoft Learn: netsh wlan](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/netsh-wlan) |

Fait partie de [09 Dépannage Wi-Fi](README.fr.md), étape 7.

---

## Objectif

Un problème intermittent est rarement présent quand le technicien regarde. Windows garde un historique des événements Wi-Fi, et `netsh wlan show wlanreport` transforme les **trois derniers jours** de cet historique en une seule page HTML : chaque session de connexion, sa durée et la raison de sa fin. Ce sont les preuves dont l'équipe réseau a besoin.

## Prérequis

- [ ] Une invite de commandes ou un PowerShell **en mode administrateur** (le rapport échoue sans droits d'administrateur)
- [ ] Les heures approximatives où l'utilisateur a remarqué les coupures
- [ ] Les services de localisation activés, sur Windows 11 24H2 et plus récent (voir l'[étape 2 du runbook](README.fr.md#étape-2--lire-létat-de-la-connexion))

## Procédure

### Étape 1 — Générer le rapport

```cmd
netsh wlan show wlanreport
```

**Résultat attendu :** la commande se termine en affichant le chemin du rapport HTML qu'elle a écrit, par défaut `C:\ProgramData\Microsoft\Windows\WlanReport\wlan-report-latest.html`. Ouvrez-le dans un navigateur.

[`Export-WifiDiagnostics.ps1 -IncludeWlanReport`](Export-WifiDiagnostics.ps1) lance cette commande et copie le rapport à côté des autres fichiers de diagnostic.

### Étape 2 — Lire d'abord le graphique de synthèse

Le haut du rapport est un graphique des sessions Wi-Fi sur les trois jours, avec une marque pour chaque erreur. Un **cercle rouge** est une erreur : sélectionnez-le pour en voir les détails.

Cherchez une tendance avant de lire les détails :

| Tendance | Indique |
|---|---|
| Erreurs à la même heure chaque jour | Quelque chose de planifié : une sauvegarde, une mise à jour, un appareil à proximité, une période achalandée |
| Erreurs seulement au réveil du portable | La gestion de l'alimentation de la carte |
| Erreurs réparties au hasard, sur un seul jour | Un événement ce jour-là : mise à jour de pilote, déménagement, changement de point d'accès |
| Sessions très courtes l'une après l'autre | Le PC se reconnecte sans arrêt : problème d'itinérance, d'authentification ou de signal |

### Étape 3 — Lire les sections

| Section | Ce qu'elle vous apprend |
|---|---|
| **Report info**, **General system info**, **User info** | Quand le rapport a été fait, le modèle du PC, la version du BIOS et de Windows, l'utilisateur |
| **Network adapters** | Chaque carte avec son pilote : vérifiez ici la date et la version du pilote Wi-Fi |
| **Script output** | Résultats enregistrés de `ipconfig /all`, `netsh wlan show all`, des certificats et des profils Wi-Fi. Les clés et les mots de passe ne sont pas affichés. |
| **Summary** : réussites et échecs des sessions | Combien de sessions ont réussi, échoué ou eu des avertissements |
| **Summary** : raisons des déconnexions | Les raisons enregistrées par Windows pour chaque déconnexion, avec leur fréquence |
| **Summary** : durées des sessions | Beaucoup de sessions courtes signifient une connexion instable |
| **Wireless sessions** | Un bloc par session : interface, profil, SSID, type de réseau et raison de la déconnexion |

### Étape 4 — Associer les raisons à une action

Lisez la formulation exacte de chaque raison de déconnexion dans le rapport et classez-la :

| La raison mentionne | Origine probable | Étape suivante |
|---|---|---|
| L'utilisateur, une demande de déconnexion, ou la désactivation du Wi-Fi | Normal : l'utilisateur ou Windows a terminé la session | Ignorer, sauf si l'utilisateur dit n'avoir rien fait |
| La mise en veille, l'alimentation, ou le retrait de la carte | Gestion de l'alimentation du PC | Paramètre **Power Management** (*Gestion de l'alimentation*) de la carte, voir l'[étape 7](README.fr.md#étape-7--coupures-répétées-recueillir-des-preuves) |
| La perte du signal, le point d'accès, ou une tentative d'itinérance | Couverture ou itinérance | Rssi au poste ([étape 3](README.fr.md#étape-3--évaluer-le-signal)), signaler l'emplacement |
| L'authentification, la sécurité, ou une clé | Profil, mot de passe, certificat ou compte | [Étape 5](README.fr.md#étape-5--corriger-une-connexion-qui-échoue) du runbook |
| Le pilote ou une erreur interne | Pilote Wi-Fi | Mettre à jour le pilote depuis le site du fabricant du PC |

Copiez le texte exact de la raison et son heure dans le billet : la formulation est plus utile à l'équipe réseau qu'un résumé.

## Vérification

- [ ] Le rapport couvre les jours et les heures de la plainte de l'utilisateur
- [ ] Chaque déconnexion de cette période a une raison classée dans le tableau ci-dessus
- [ ] Après la correction, un nouveau rapport un ou deux jours plus tard ne montre aucune nouvelle erreur du même type

## Dépannage

| Symptôme | Cause probable | Correction |
|---|---|---|
| `The requested operation requires elevation` | Commande lancée sans droits d'administrateur | Ouvrir l'invite de commandes ou PowerShell **en tant qu'administrateur** |
| Le rapport est vide ou très court | Le PC était éteint, ou sur un câble, pendant la période | Demander à l'utilisateur de travailler en Wi-Fi pendant une journée, puis le générer de nouveau |
| Le problème a eu lieu il y a plus de trois jours | Le rapport ne garde que trois jours | Le générer dès que l'utilisateur appelle, et lui demander d'appeler pendant la prochaine occurrence |

## Retour arrière

Rien à annuler : le rapport ne fait que lire l'historique des événements et écrire un fichier HTML. Supprimez la copie du bureau ou du dossier du billet quand le billet est fermé, car elle contient des noms de réseaux et des adresses matérielles.

---

<sub>Écrit par bazeeza · Vous avez trouvé une erreur ? <a href="https://github.com/Bazeeza/Technical-Runbooks/issues/new?template=runbook-error.yml">Signalez-la ici</a>.</sub>
