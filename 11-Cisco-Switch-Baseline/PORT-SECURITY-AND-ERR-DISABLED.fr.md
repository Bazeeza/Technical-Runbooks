# Sécurité des ports et ports err-disabled : lire, rétablir, prévenir

[![Français](https://img.shields.io/badge/Langue-Français-3fe0a0?style=for-the-badge)](PORT-SECURITY-AND-ERR-DISABLED.fr.md)
[![English](https://img.shields.io/badge/Language-English-2b9dff?style=for-the-badge)](PORT-SECURITY-AND-ERR-DISABLED.md)

![Level](https://img.shields.io/badge/Level-Intermediate-ffb454?style=flat-square)
![Time](https://img.shields.io/badge/Time-5%E2%80%9315%20min-2b9dff?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Cisco%20IOS%20%7C%20IOS%20XE-1BA0D7?style=flat-square)
![Reviewed](https://img.shields.io/badge/Last%20reviewed-2026--10-555?style=flat-square)

| Élément | Contenu |
|---|---|
| **Référent** | Un port utilisateur qui cesse de fonctionner parce que la sécurité des ports (port security) ou BPDU guard a réagi. |
| **Émetteur** | **bazeeza** |
| **Message** | Trouver pourquoi un port est bloqué ou err-disabled, le rétablir de façon sûre, et décider si c'est la protection ou l'utilisateur qui avait raison. |
| **Récepteur** | Techniciens du soutien technique et techniciens terrain avec un accès en lecture au commutateur, techniciens réseau débutants. |
| **Canal** | Dépôt GitHub `Bazeeza/Technical-Runbooks` |
| **Code** | Français, rédaction technique (traduction de l'original anglais) · Cisco IOS CLI |
| **Référence** | [Cisco: Port Security, Catalyst 9300 Security Configuration Guide (IOS XE 17.9)](https://www.cisco.com/c/en/us/td/docs/switches/lan/catalyst9300/software/release/17-9/configuration_guide/sec/b_179_sec_9300_cg/port_security.html) · [Cisco: Harden IOS Devices](https://www.cisco.com/c/en/us/support/docs/ip/access-lists/13608-21.html) |

---

## Objectif

La [configuration de base](README.fr.md) protège chaque port utilisateur avec la **sécurité des ports** (un nombre maximal d'adresses MAC) et **BPDU guard** (aucun commutateur ne peut être branché sur un port utilisateur). Quand l'une d'elles réagit, l'utilisateur voit seulement que « le réseau est en panne ». Cette page explique ce que le commutateur a fait, comment le prouver et comment rétablir le port sans simplement désactiver la protection.

## Prérequis

- [ ] Un accès console ou SSH au commutateur, en mode EXEC privilégié (`enable`) pour les étapes de rétablissement
- [ ] Le numéro du port (d'après l'étiquette de la prise murale et le panneau de brassage, voir le [runbook 08](../08-Network-Cabling-and-Termination/PATCH-PANEL-AND-LABELING.fr.md))
- [ ] Ce qui était branché : PC seul, téléphone et PC, petit commutateur, station d'accueil

---

## Les trois modes de violation

| Mode | Trafic d'une nouvelle adresse MAC | Journal et compteur | État du port | Usage typique |
|---|---|---|---|---|
| `protect` | Rejeté | **Aucun** | Reste actif | Rarement : les violations sont invisibles |
| `restrict` | Rejeté | Message syslog, trap SNMP, le compteur augmente | Reste actif | Ports utilisateurs de la configuration de base : les appareils connus continuent de fonctionner |
| `shutdown` (par défaut) | Le port s'arrête | Message syslog, le compteur augmente | **err-disabled**, voyant éteint | Ports sensibles où tout appareil en trop doit tout arrêter |

> [!NOTE]
> La configuration de base définit `maximum 3` sur les ports utilisateurs : le PC, le téléphone IP, et de la place pour un téléphone vu d'abord dans le VLAN de données pendant son démarrage. Un utilisateur qui ajoute un petit commutateur non géré avec deux appareils de plus dépasse la limite.

## Étape 1 — Voir l'état du port

```text
show interfaces status
show interfaces status err-disabled
```

**Résultat attendu :** un port qui fonctionne affiche `connected` avec son VLAN. Un port bloqué par une violation en mode `shutdown`, ou par BPDU guard, affiche `err-disabled`. La deuxième commande ajoute la **raison** (`psecure-violation`, `bpduguard`, `link-flap`...).

## Étape 2 — Lire les compteurs de la sécurité des ports

```text
show port-security
show port-security interface GigabitEthernet1/0/7
show port-security address
```

| Champ | Ce qu'il indique |
|---|---|
| **Port Security** | `Enabled` |
| **Port Status** | `Secure-up`, ou `Secure-shutdown` après une violation en mode `shutdown` |
| **Violation Mode** | `Restrict` sur les ports utilisateurs de la configuration de base |
| **Maximum MAC Addresses** / **Total MAC Addresses** | Limite et nombre actuel : s'ils sont égaux, le prochain nouvel appareil est refusé |
| **Security Violation Count** | Augmente à chaque trame refusée |
| **Last Source Address:Vlan** | L'adresse MAC qui a causé la dernière violation |

En mode `restrict`, le port reste `connected` : cette commande est donc le seul moyen de voir qu'un appareil est refusé.

## Étape 3 — Identifier l'appareil en trop

```text
show mac address-table interface GigabitEthernet1/0/7
show cdp neighbors GigabitEthernet1/0/7 detail
show logging | include PSECURE|BPDUGUARD
```

Les six premiers chiffres hexadécimaux d'une adresse MAC (l'OUI) identifient le fabricant : un téléphone, une station d'accueil, une imprimante, un commutateur grand public. CDP (ou LLDP) affiche les téléphones et commutateurs Cisco par leur nom. Le journal donne l'heure de la violation, à comparer avec ce que l'utilisateur a fait.

| Ce que vous trouvez | Décision |
|---|---|
| Un nouveau PC a remplacé l'ancien | Légitime : effacer l'ancienne adresse (étape 4) |
| Une station d'accueil avec sa propre carte réseau, plus le PC | Légitime : l'utilisateur doit utiliser une seule connexion réseau, pas les deux |
| Un petit commutateur ou un routeur domestique sous le bureau | Non autorisé : le retirer, puis rétablir le port |
| Un appareil inconnu | Ne pas rétablir le port : escalader comme incident de sécurité possible |

## Étape 4 — Rétablir le port

**Effacer les adresses apprises** (par exemple après le remplacement d'un PC) :

```text
clear port-security dynamic interface GigabitEthernet1/0/7
```

**Remettre en service un port err-disabled**, une fois la cause retirée :

```text
configure terminal
interface GigabitEthernet1/0/7
 shutdown
 no shutdown
end
```

**Résultat attendu :** `show interfaces status` affiche de nouveau le port `connected` en quelques secondes (aucun délai du spanning tree, grâce à `portfast`).

> [!WARNING]
> Ne corrigez jamais une violation en retirant `switchport port-security` ou `spanning-tree bpduguard enable` du port. La protection a fait son travail : retirez la cause, puis rétablissez le port, et notez les deux dans le billet.

## Étape 5 — Facultatif : rétablissement automatique

Un site peut décider que les ports err-disabled reviennent d'eux-mêmes après un délai :

```text
configure terminal
errdisable recovery cause psecure-violation
errdisable recovery cause bpduguard
errdisable recovery interval 300
end
show errdisable recovery
```

Si la cause est toujours branchée, le port est désactivé de nouveau après 300 secondes. C'est une décision de politique du site, pas du soutien technique : sans elle, un port reste err-disabled jusqu'à ce que quelqu'un le rétablisse à la main.

---

## Vérification

- [ ] `show interfaces status` affiche le port `connected` dans le bon VLAN
- [ ] `show port-security interface` affiche un total inférieur au maximum et aucune nouvelle violation
- [ ] Le PC et le téléphone de l'utilisateur fonctionnent tous les deux (téléphone enregistré, PC avec une adresse dans le VLAN de données)
- [ ] Le billet nomme l'appareil qui a causé la violation et ce qui en a été fait

## Dépannage

| Symptôme | Cause probable | Correction |
|---|---|---|
| Port `err-disabled`, raison `bpduguard` | Un commutateur, ou un PC qui relie deux cartes réseau en pont, a envoyé des trames spanning tree | Retirer l'appareil, rétablir le port |
| Le téléphone fonctionne, pas le PC derrière lui | Maximum atteint par le téléphone dans deux VLAN plus le PC | Vérifier `show port-security address` ; la valeur 3 de la configuration de base couvre ce cas |
| Violations chaque matin, sans nouvel appareil | Un PC avec une adresse MAC aléatoire ou changeante | Vérifier les paramètres de la carte réseau, ou la station d'accueil qui ajoute sa propre adresse |
| Port `err-disabled`, raison `link-flap` | Câble endommagé ou carte réseau défaillante | [Test des câbles](../08-Network-Cabling-and-Termination/CABLE-TESTING.fr.md), puis rétablir le port |

## Retour arrière

Rétablir un port ne change pas la configuration. Si un site décide d'augmenter le maximum sur un port, la modification tient en une ligne (`switchport port-security maximum 4`) et s'annule de la même façon ; notez la raison dans le billet et dans la description du port.

---

<sub>Écrit par bazeeza · Vous avez trouvé une erreur ? <a href="https://github.com/Bazeeza/Technical-Runbooks/issues/new?template=runbook-error.yml">Signalez-la ici</a>.</sub>
