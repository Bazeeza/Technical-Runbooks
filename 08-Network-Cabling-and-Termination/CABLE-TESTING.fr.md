# Tester un câble en cuivre et lire les défauts du schéma de câblage

[![Français](https://img.shields.io/badge/Langue-Français-3fe0a0?style=for-the-badge)](CABLE-TESTING.fr.md)
[![English](https://img.shields.io/badge/Language-English-2b9dff?style=for-the-badge)](CABLE-TESTING.md)

![Level](https://img.shields.io/badge/Level-Beginner%20to%20Intermediate-ffb454?style=flat-square)
![Time](https://img.shields.io/badge/Time-2%E2%80%9310%20min%20per%20cable-2b9dff?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Copper%20cabling-555?style=flat-square)
![Reviewed](https://img.shields.io/badge/Last%20reviewed-2026--10-555?style=flat-square)

| Élément | Contenu |
|---|---|
| **Référent** | Tester un câble à paires torsadées après sa terminaison, et identifier le défaut quand il échoue. |
| **Émetteur** | **bazeeza** |
| **Message** | Choisir le bon niveau de test, lire chaque défaut du schéma de câblage (*wire map*) et savoir quelle réparation il demande. |
| **Récepteur** | Techniciens terrain, techniciens en câblage, techniciens de soutien TI, étudiants en informatique. |
| **Canal** | Dépôt GitHub `Bazeeza/Technical-Runbooks` |
| **Code** | Français, rédaction technique (traduction de l'original anglais) · testeurs de câbles portatifs, générateur de tonalité et sonde |
| **Référence** | [Fluke Networks: wire map testing, it's not all about color](https://www.flukenetworks.com/blog/cabling-chronicles/wire-map-testing-it-s-not-all-about-color) · [Fluke Networks: diagnosing wiremap faults](https://www.flukenetworks.com/knowledge-base/microscanner2/diagnosing-wiremap-faults-microscanner2) · [Fluke Networks: how to use a network cable tester](https://www.flukenetworks.com/knowledge-base/how-to-use-network-cable-tester) · [Fluke Networks: 10GBASE-T field testing requirements](https://www.flukenetworks.com/knowledge-base/applicationstandards-articles-copper/10gbase-t-field-testing-requirements) |

Fait partie de [08 Câblage réseau et terminaison](README.fr.md), étape 6.

---

## Objectif

Un câble qui « a l'air correct » peut quand même être mauvais : deux paires échangées, un fil sur la mauvaise broche, ou une paire séparée (*split pair*) qui réussit un test de continuité et échoue sous un vrai trafic. Chaque câble terminé est testé **avant** d'être branché à un équipement, et le résultat est noté dans le billet ou dans le registre de câblage.

## Prérequis

- [ ] Un testeur de câbles avec son **unité distante** (la partie branchée à l'extrémité éloignée)
- [ ] Deux cordons de brassage courts et réputés bons, pour relier le testeur à la prise murale et au panneau de brassage
- [ ] Le schéma de câblage utilisé sur ce site (T568A ou T568B) réglé dans le testeur
- [ ] L'étiquette du câble, pour noter le résultat au nom du bon câble

## Trois niveaux de test

| Niveau | Question à laquelle il répond | Outil typique | Quand il suffit |
|---|---|---|---|
| **Vérification** | Chaque fil est-il relié à la bonne broche, et quelle est la longueur du câble ? | Testeur de schéma de câblage avec unité distante | Cordons de brassage, réparations, petits bureaux, dépannage |
| **Qualification** | Ce lien peut-il transporter une vitesse Ethernet donnée (1 Gb/s, 10 Gb/s) et le PoE ? | Testeur de qualification | Vérifier que le câblage existant permet une mise à niveau |
| **Certification** | Ce lien respecte-t-il toutes les limites de sa catégorie (TIA-568 ou ISO/IEC 11801) ? | Analyseur de certification | Nouvelles installations, garanties des fabricants, remise à un client |

Un technicien de soutien ou de terrain fait habituellement de la **vérification**. Un câble qui réussit un test de schéma de câblage est correctement câblé ; il n'est pas prouvé qu'il atteint les performances Cat 6 ou Cat 6A. Seul un test de certification le prouve.

## Procédure

### Étape 1 — Préparer le testeur

Réglez le schéma de câblage (T568A ou T568B, le même que l'installation), le type de câble et la limite de test si le testeur en a une. Vérifiez que la pile est chargée : une pile faible peut donner de faux résultats sur certains testeurs.

**Résultat attendu :** les réglages du testeur correspondent au câble que vous allez tester.

### Étape 2 — Brancher les deux extrémités

Branchez l'unité principale à une extrémité (port du panneau de brassage) et l'unité distante à l'autre (prise murale), chacune par un cordon de brassage court et réputé bon.

Pour trouver quelle prise correspond à quel port dans une installation non étiquetée, utilisez un **générateur de tonalité** à une extrémité et la **sonde** à l'autre : la sonde sonne le plus fort sur le bon câble. Certains testeurs peuvent aussi faire **clignoter** un port de commutateur branché, ce qui identifie le port sans rien débrancher.

### Étape 3 — Lancer le test et lire le schéma de câblage

Lancez le test automatique. Le schéma de câblage montre, pour chaque broche à l'extrémité proche, la broche qu'elle atteint à l'extrémité éloignée.

**Résultat attendu :** les broches 1 à 8 atteignent chacune la même broche à l'autre extrémité (droit), chaque paire est indiquée **pass** (réussie) et la longueur est plausible (un peu plus que la distance tirée, jamais plus de 90 m pour un lien permanent).

### Étape 4 — Identifier le défaut

| Défaut | Ce que montre le testeur | Cause habituelle | Correction |
|---|---|---|---|
| **Ouvert** (*open*) | Un fil n'atteint aucune broche à l'extrémité éloignée | Fil mal inséré dans l'IDC ou la fiche, câble coupé ou endommagé | Refaire la terminaison de l'extrémité où le testeur situe le défaut (distance jusqu'au défaut) |
| **Court-circuit** (*short*) | Deux fils ou plus reliés ensemble | Câble écrasé, connecteur endommagé, brin de cuivre égaré dans la fiche | Refaire la terminaison ; si le court-circuit est au milieu du câble, remplacer le câble |
| **Paire inversée** (*reversed pair*) | Les deux fils d'une paire sont échangés (par exemple 1-2 arrive en 2-1) | Couleurs d'une paire inversées à une extrémité | Refaire cette extrémité, le fil rayé blanc sur la broche impaire |
| **Paires croisées** (*crossed pairs*) | Deux paires échangées (par exemple 1-2 arrive sur 3-6) | Une extrémité en T568A et l'autre en T568B | Refaire une extrémité avec le schéma du site |
| **Paire séparée** (*split pair*) | Continuité correcte broche à broche, mais les fils de deux paires sont mélangés | Fils pris dans deux paires différentes pour les broches 3-6, de la même façon aux deux extrémités | Refaire les deux extrémités avec les bonnes paires |
| **Erreur de câblage** (*miswire*) | Toute autre mauvaise attribution de broche | Ordre des couleurs non respecté | Refaire l'extrémité défectueuse |

> [!WARNING]
> La **paire séparée** est le piège : un simple testeur de continuité la montre comme bonne, car chaque broche atteint la même broche. Mais le signal circule sur des fils qui ne sont pas torsadés ensemble, donc la diaphonie devient très élevée et le lien échoue ou descend à une vitesse plus basse. Seul un testeur qui mesure la diaphonie la détecte. Suivre exactement le code de couleurs l'évite.

### Étape 5 — Noter le résultat

Enregistrez le résultat dans le testeur avec l'étiquette du câble comme nom, ou écrivez-le dans le registre de câblage : étiquette, date, longueur, réussite/échec, testeur utilisé. Un résultat d'échec enregistré est utile aussi : il montre ce qui a été réparé.

## Vitesses et longueurs à retenir

| Catégorie | Bande passante | 1000BASE-T à 100 m | 10GBASE-T |
|---|---|---|---|
| **Cat 5e** | 100 MHz | Oui | Non pris en charge |
| **Cat 6** | 250 MHz | Oui | Jusqu'à 37 m, et jusqu'à 55 m selon la diaphonie exogène (TIA TSB-155) |
| **Cat 6A** | 500 MHz | Oui | Oui, 100 m |

Le **canal de 100 m** se compose d'au plus **90 m de lien permanent** (du panneau de brassage à la prise murale, dans les murs) plus au plus **10 m de cordons de brassage** au total aux deux extrémités.

## Vérification

- [ ] Chaque câble testé avec un résultat réussi, les deux extrémités branchées au testeur
- [ ] Longueur inférieure à 90 m pour chaque lien permanent
- [ ] Résultats enregistrés ou notés au nom de l'étiquette du câble

## Dépannage

| Symptôme | Cause probable | Correction |
|---|---|---|
| Le testeur affiche « no remote » (aucune unité distante) ou tous les fils ouverts | Unité distante non branchée à ce câble, ou mauvaise prise | Générateur de tonalité et sonde pour trouver la bonne prise |
| Le câble réussit le schéma de câblage, mais le PC ne se connecte qu'à 100 Mb/s | Paire endommagée (le gigabit utilise les quatre paires), paire séparée ou mauvais cordon de brassage | Remplacer d'abord les cordons de brassage, puis refaire la terminaison ; tester avec un testeur de qualification |
| Longueur bien plus grande que prévu | Câble enroulé dans le plafond, ou testeur réglé sur le mauvais type de câble (NVP) | Vérifier le réglage du type de câble ; le surplus de câble n'est pas un défaut s'il reste sous 90 m |
| Le défaut n'apparaît que quand on bouge le câble | Fils mal insérés, ou la fiche n'a pas serré la gaine | Refaire la terminaison avec un serrage sur la gaine |

## Retour arrière

Une terminaison qui échoue est coupée et refaite : gardez pour cela quelques centimètres de mou à chaque extrémité. Ne laissez jamais un câble en échec branché « parce que le lien monte » : notez-le comme en échec et réparez-le.

---

<sub>Écrit par bazeeza · Vous avez trouvé une erreur ? <a href="https://github.com/Bazeeza/Technical-Runbooks/issues/new?template=runbook-error.yml">Signalez-la ici</a>.</sub>
