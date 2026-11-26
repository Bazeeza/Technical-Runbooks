# Préparation du réseau pour la voix : codecs, bande passante, QoS, VLAN voix et PoE

[![Français](https://img.shields.io/badge/Langue-Français-3fe0a0?style=for-the-badge)](VOICE-NETWORK-READINESS.fr.md)
[![English](https://img.shields.io/badge/Language-English-2b9dff?style=for-the-badge)](VOICE-NETWORK-READINESS.md)

![Level](https://img.shields.io/badge/Level-Intermediate-ffb454?style=flat-square)
![Time](https://img.shields.io/badge/Time-20%20min-2b9dff?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Cisco%20IOS%20%7C%20SIP-1BA0D7?style=flat-square)
![Reviewed](https://img.shields.io/badge/Last%20reviewed-2026--10-555?style=flat-square)

| Élément | Contenu |
|---|---|
| **Référent** | Ce que le réseau doit fournir pour que les téléphones IP sonnent bien : assez de bande passante, la priorité pour la voix, un VLAN voix et l'alimentation. |
| **Émetteur** | **bazeeza** |
| **Message** | Dimensionner la bande passante d'un ensemble d'appels, vérifier le marquage DSCP, le VLAN voix et le budget PoE d'un commutateur avant d'accuser un téléphone. |
| **Récepteur** | Techniciens terrain et techniciens réseau qui installent ou soutiennent des téléphones IP, étudiants en télécommunications. |
| **Canal** | Dépôt GitHub `Bazeeza/Technical-Runbooks` |
| **Code** | Français, rédaction technique (traduction de l'original anglais) · CLI Cisco IOS |
| **Référence** | [Cisco: Voice over IP, per call bandwidth consumption](https://www.cisco.com/c/en/us/support/docs/voice/voice-quality/7934-bwidth-consume.html) · [RFC 4594: Configuration guidelines for DiffServ service classes](https://www.rfc-editor.org/rfc/rfc4594) · [RFC 6716: Opus codec](https://www.rfc-editor.org/rfc/rfc6716) · [Cisco: Voice VLAN configuration example](https://www.cisco.com/c/en/us/support/docs/switches/catalyst-2950-series-switches/113260-voice-vlan-00.html) · ITU-T G.114 (one-way transmission time) |

---

## Objectif

Une voix hachée, robotique ou en retard est rarement la faute du téléphone. La voix a besoin d'un flux de paquets petit mais **régulier** : quelques paquets perdus ou en retard s'entendent immédiatement, alors qu'un téléchargement de fichier ne le remarquerait pas. Cette page liste ce qu'il faut vérifier du côté du réseau, avec les valeurs de comparaison.

Retour au runbook principal : [10 Dépannage des téléphones VoIP / SIP](README.fr.md).

## Prérequis

- [ ] Le nombre d'appels simultanés dont le site a besoin (ou le nombre de canaux du *trunk*)
- [ ] Un accès en lecture au commutateur d'accès (commandes `show`)
- [ ] La fiche technique du modèle de téléphone (classe PoE)

---

## Objectifs de qualité

| Mesure | Cible pour une bonne voix | Ce que l'utilisateur entend au-delà |
|---|---|---|
| Délai dans un sens (de la bouche à l'oreille) | 150 ms ou moins (ITU-T G.114) | Les gens parlent en même temps |
| Gigue (variation du délai) | Moins d'environ 30 ms | Voix hachée ou robotique quand la mémoire tampon de gigue se vide |
| Perte de paquets | Moins de 1 % | Syllabes manquantes, clics |

La gigue et la perte viennent de la **congestion** : une liaison montante ou un lien Internet saturé à l'heure de pointe. C'est pourquoi la QoS et la planification de la bande passante comptent plus que la vitesse brute.

## Codecs

| Codec | Bande audio | Débit du codec | Bande passante Ethernet par appel, par sens (paquets de 20 ms) | Remarques |
|---|---|---|---|---|
| **G.711** (µ-law en Amérique du Nord, A-law ailleurs) | Bande étroite, qualité téléphonique | 64 kbps | 87,2 kbps | Universel, sans compression, idéal pour le réseau local et la plupart des *trunks* SIP |
| **G.722** | Bande élargie (« voix HD ») | 64 kbps | Comme G.711 | Voix plus claire entre les téléphones qui le prennent en charge ; même bande passante |
| **G.729** | Bande étroite | 8 kbps | 31,2 kbps | Économise la bande passante sur les liens lents ; qualité moindre, mauvais pour le télécopieur et les tonalités |
| **Opus** | De la bande étroite à la bande complète, adaptatif | 6 à 510 kbps, variable | Varie selon le débit configuré | S'adapte au réseau, courant dans les téléphones logiciels et WebRTC |

La valeur Ethernet est plus grande que le débit du codec, car chaque paquet de 20 ms transporte aussi les en-têtes RTP, UDP, IP et Ethernet. La bande passante est nécessaire **dans chaque sens** : sur un lien symétrique, 10 appels G.711 demandent environ 872 kbps en montée **et** 872 kbps en descente, avant tout surcoût de VPN.

> [!NOTE]
> Les deux extrémités doivent avoir un codec en commun. Sinon, l'appel échoue avec `488 Not Acceptable Here`, ou le PBX **transcode** (convertit) d'un codec à l'autre, ce qui coûte du processeur et un peu de qualité. Voir [Lire un appel SIP](SIP-CALL-FLOW.fr.md).

## Marquage QoS : DSCP

Les paquets de voix sont marqués dans l'en-tête IP pour que chaque routeur et chaque commutateur sur le chemin les serve en premier.

| Trafic | Nom DSCP | Valeur DSCP | Remarques |
|---|---|---|---|
| Média de la voix (RTP) | **EF** (Expedited Forwarding) | **46** | Identique dans la RFC 4594 et dans les architectures des fabricants : placer dans une file prioritaire |
| Signalisation d'appel (SIP) | CS3 | 24 | Courant dans les architectures Cisco ; la RFC 4594 recommande CS5 (40). Suivre la politique QoS du site |
| Tout le reste venant du PC | Default | 0 | Sauf si la politique du site dit autre chose |

La plupart des téléphones IP marquent EF et CS3 par défaut (un paramètre du téléphone ou de son modèle de provisionnement). Le marquage n'aide que là où le réseau lui **fait confiance** et dispose d'une file prioritaire : sur les commutateurs du réseau local, et sur le routeur WAN avant un lien lent. L'Internet public ignore le DSCP : c'est pourquoi la voix sur un simple lien Internet dépend d'une bande passante disponible en réserve.

Pour voir le marquage, capturez un appel avec Wireshark sur un port en miroir et lisez **Differentiated Services Field** dans l'en-tête IP des paquets RTP.

## VLAN voix

Le téléphone et le PC partagent un seul câble et un seul port de commutateur, mais pas le même VLAN :

```mermaid
flowchart LR
    PC["PC<br/>trames non étiquetées"] --> PH["Téléphone IP<br/>commutateur intégré"]
    PH -->|"données : non étiquetées, VLAN 10<br/>voix : étiquetées 802.1Q, VLAN 20"| SW["Port du commutateur d'accès<br/>switchport voice vlan 20"]
    SW -->|trunk| CORE[Réseau]
```

1. Le commutateur indique au téléphone quel VLAN utiliser pour la voix : **CDP** pour les téléphones Cisco, **LLDP-MED** pour la plupart des autres marques (`lldp run` sur le commutateur), ou des options DHCP sur certains systèmes.
2. Le téléphone étiquette ses propres trames avec le VLAN 20 et une priorité ; il laisse passer les trames du PC sans étiquette, elles arrivent donc dans le VLAN d'accès 10.
3. La voix est dans son propre sous-réseau : étendue DHCP distincte, facile à prioriser et à filtrer.

Vérification sur le commutateur :

```text
show interfaces GigabitEthernet1/0/7 switchport
show cdp neighbors GigabitEthernet1/0/7 detail
show lldp neighbors GigabitEthernet1/0/7 detail
```

**Résultat attendu :** `Access Mode VLAN: 10`, `Voice VLAN: 20`, et le téléphone listé comme voisin. Un téléphone qui démarre dans le VLAN 10 et obtient une adresse **de données** n'a pas appris le VLAN voix : vérifiez que CDP ou LLDP est activé sur le port.

La configuration complète du port se trouve dans la [configuration de base d'un commutateur Cisco](../11-Cisco-Switch-Baseline/README.fr.md).

## Alimentation par Ethernet (PoE)

| Norme | Type PoE | Puissance au port du commutateur | Puissance disponible à l'appareil |
|---|---|---|---|
| IEEE 802.3af (PoE) | Type 1 | 15,4 W | 12,95 W |
| IEEE 802.3at (PoE+) | Type 2 | 30 W | 25,5 W |
| IEEE 802.3bt (PoE++) | Type 3 | 60 W | 51 W |
| IEEE 802.3bt (PoE++) | Type 4 | 90 W | 71,3 W |

La plupart des téléphones de bureau se contentent du 802.3af ; un téléphone avec un écran couleur et un module d'extension peut avoir besoin du PoE+. Le commutateur a aussi un **budget de puissance total** : un commutateur de 24 ports ne peut pas toujours fournir la pleine puissance à tous les ports en même temps.

```text
show power inline
show power inline GigabitEthernet1/0/7 detail
```

**Résultat attendu :** le port affiche `on` avec la puissance consommée et la classe de l'appareil. `off`, `faulty` ou `power-deny` signifie que l'appareil a demandé plus que ce que le port ou le budget restant peut fournir.

> [!TIP]
> Un téléphone qui redémarre quand on branche son module d'extension, ou plusieurs téléphones qui s'éteignent quand un nouveau point d'accès est branché, désignent le budget PoE, pas les téléphones.

---

## Vérification

- [ ] La bande passante pour le nombre prévu d'appels simultanés, dans chaque sens, reste sous la capacité du lien à l'heure de pointe
- [ ] Les paquets RTP sont marqués EF (46) dans une capture
- [ ] Le téléphone est dans le VLAN voix, avec une adresse de l'étendue voix
- [ ] `show power inline` montre le téléphone alimenté, avec du budget restant sur le commutateur

## Dépannage

| Symptôme | Cause probable | Correction |
|---|---|---|
| Voix hachée seulement aux heures de pointe | Liaison montante ou lien Internet congestionné, aucune file prioritaire | Vérifier l'utilisation du lien ; demander à l'équipe réseau de la QoS sur ce lien |
| Le téléphone obtient une adresse dans le sous-réseau de données | VLAN voix non appris (CDP ou LLDP désactivé, ou non pris en charge) | Activer CDP ou `lldp run` ; vérifier le paramètre de VLAN du téléphone |
| Le téléphone ne s'allume pas, le PC derrière lui fonctionne | PoE désactivé sur le port, budget épuisé, ou commutateur sans PoE | `show power inline` ; utiliser un injecteur PoE pour tester |
| Appels corrects sur place, mauvais par le VPN | Surcoût du VPN plus une connexion résidentielle lente | Utiliser G.711 seulement là où la bande passante le permet, ou un codec à plus faible débit pour les employés à distance |

## Retour arrière

Cette page ne fait que vérifier le réseau. Les modifications de QoS, de VLAN ou de PoE sont faites par l'équipe réseau, selon sa propre procédure de changement.

---

<sub>Écrit par bazeeza · Vous avez trouvé une erreur ? <a href="https://github.com/Bazeeza/Technical-Runbooks/issues/new?template=runbook-error.yml">Signalez-la ici</a>.</sub>
