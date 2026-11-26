# Guide de style de la documentation

[![Français](https://img.shields.io/badge/Langue-Français-3fe0a0?style=for-the-badge)](STYLE.fr.md)
[![English](https://img.shields.io/badge/Language-English-2b9dff?style=for-the-badge)](STYLE.md)

| Élément | Contenu |
|---|---|
| Objectif | Rendre chaque README et chaque document des dépôts `Bazeeza` bilingue, facile à parcourir et cohérent |
| Technologies | Markdown (GitHub Flavored), badges shields.io, Mermaid, PowerShell 5.1 pour la vérification automatique |
| Niveau | Débutant |
| Contenu | Boutons de langue, tableau « en un coup d'œil », arborescence du dépôt, style visuel, règles de traduction et de confidentialité |
| Statut | En cours |
| Lire en premier | [1. Boutons de langue](#1-boutons-de-langue) |

Ce guide s'applique aux fichiers `README.md` et aux autres documents `.md` des dépôts. Il complète le [modèle de runbook](../TEMPLATE.fr.md), qui décrit l'**intérieur** d'un runbook (objectif, procédure, vérification, retour arrière) ; ce guide décrit ce qui l'entoure : la langue, le premier écran et la présentation.

> [!NOTE]
> **Règle d'or : on ajoute, on ne change pas.** Le texte, les fichiers, les dossiers et les liens existants restent tels quels. Une traduction, un tableau ou une arborescence est **ajouté**. Les seules exceptions sont le retrait des noms de personnes et la réorganisation d'un README difficile à lire, sans perdre aucune information.

---

## 1. Boutons de langue

GitHub n'exécute pas de JavaScript dans un README : le sélecteur de langue est donc fait de deux badges shields.io cliquables, placés sur la **première ligne sous le titre**, sans emoji :

```markdown
[![Français](https://img.shields.io/badge/Langue-Français-3fe0a0?style=for-the-badge)](README.fr.md)
[![English](https://img.shields.io/badge/Language-English-2b9dff?style=for-the-badge)](README.md)
```

| Langue d'origine du document | Nom de l'original | Nom de la traduction |
|---|---|---|
| Anglais (Technical-Runbooks, helpdesk-toolkit, homelab-infrastructure, thm-badge-finder) | `X.md` | `X.fr.md` |
| Français (Projets-Runbooks, webdingo-noc-lab) | `X.md` | `X.en.md` |

- La langue d'origine d'un document **ne change jamais** : `X.md` reste l'original, la jumelle reçoit le suffixe de langue.
- Les deux boutons apparaissent dans les **deux** fichiers, dans le même ordre (français d'abord, anglais ensuite). Chaque bouton pointe vers le fichier dans sa langue, pour que le lecteur puisse toujours revenir en arrière.
- Les liens d'un document traduit pointent vers les documents traduits quand ils existent (`../04-Network-Troubleshooting/README.fr.md`), sinon vers l'original.

## 2. Le tableau « en un coup d'œil »

Juste après les boutons, un tableau de six lignes dit au lecteur en dix secondes de quoi parle le dossier :

| Français | Anglais | Quoi écrire |
|---|---|---|
| Élément \| Contenu | Item \| Details | Ligne d'en-tête |
| Objectif | Goal | Une phrase : ce que le projet ou le document permet de faire |
| Technologies | Technologies | Les outils réellement utilisés, lus dans les fichiers |
| Niveau | Level | Débutant, Intermédiaire ou Avancé |
| Contenu | Contents | Ce que contient le dossier : procédure, scripts, schémas, résultats |
| Statut | Status | Terminé, En cours ou Archivé |
| Lire en premier | Start here | Lien vers le fichier le plus utile |

> [!IMPORTANT]
> Seulement des lignes **vérifiables**. Quand une valeur ne peut pas être lue dans les fichiers (par exemple le statut d'un ancien projet de cours), la ligne est retirée, jamais devinée.

Les runbooks commencent déjà par leur propre tableau d'en-tête (Référent, Émetteur, Message...). Ils le gardent : le tableau « en un coup d'œil » est ajouté aux README des dépôts, des cours et des projets, pas dans chaque runbook.

## 3. L'arborescence du dépôt

Le README racine de chaque dépôt, et le README de chaque dossier de cours ou de projet, montre l'arborescence **réelle** dans un bloc `text`, lue sur le disque, avec un commentaire d'une ligne par dossier. Extrait de ce dépôt :

```text
Technical-Runbooks/
├── 01-PC-Boot-Process-and-BIOS-UEFI/   Étapes du démarrage, réglages du micrologiciel, réparation
├── 02-Windows-11-Clean-Installation/   Installation propre et liste de contrôle après installation
├── docs/                               Guide de style (ce fichier)
├── scripts/                            Vérifications du dépôt (Test-ReadmePair.ps1)
└── TEMPLATE.md                         Modèle pour un nouveau runbook
```

Sous l'arborescence, un tableau ou une liste donne un lien vers chaque sous-README, car les liens ne fonctionnent pas dans un bloc de code. L'arborescence française a des commentaires en français, l'anglaise en anglais ; les noms de dossiers et de fichiers ne sont jamais traduits.

## 4. Un document qui donne envie de lire

| Élément | Règle |
|---|---|
| Titre | Centré dans le README d'un dépôt (`<h1 align="center">`), titre `#` simple dans les autres documents |
| Accroche | Une phrase sous le titre qui dit ce que le lecteur y gagne |
| Badges | shields.io, style `flat-square` pour l'information, `for-the-badge` seulement pour les boutons de langue |
| Couleurs | `#3fe0a0` vert, `#2b9dff` bleu, `#ffb454` orange, `#c792ea` violet, sur fond `#070d1c` dans les schémas |
| Sections | Courtes, une idée chacune, avec un tableau quand plusieurs éléments sont comparés |
| Encadrés | `> [!NOTE]`, `> [!TIP]`, `> [!IMPORTANT]`, `> [!WARNING]` pour ce qu'il ne faut pas manquer |
| Schémas | Mermaid quand les fichiers permettent de le dessiner sans rien inventer |
| Navigation | Dans une série, un pied de page `← Précédent · Sommaire · Suivant →` (`← Previous · Contents · Next →` en anglais) |
| Emoji | Aucun dans les textes publics : les lecteurs d'écran les annoncent un par un et leur rendu change selon la plateforme |

Règles Mermaid qui évitent les erreurs d'affichage sur GitHub :

- une étiquette ne commence jamais par un nombre suivi d'un point (`1. Installer` est lu comme une liste) : écrire `Étape 1 - Installer` ;
- les étiquettes qui contiennent des parenthèses, des barres obliques ou des deux-points sont entre guillemets : `A["Serveur (AWS)"]` ;
- `classDef` utilise les couleurs ci-dessus, par exemple `classDef network fill:#070d1c,stroke:#2b9dff,color:#2b9dff`.

## 5. Règles de traduction

| Traduit | Jamais traduit |
|---|---|
| Titres, paragraphes, texte des tableaux, commentaires des arborescences, texte alternatif des images | Code, commandes, paramètres, noms de fichiers et de dossiers, sorties de terminal, fichiers de configuration, noms de produits |

- Les deux versions ont **les mêmes sections dans le même ordre, les mêmes liens et les mêmes commandes**. Une modification d'une version est faite dans l'autre le même jour.
- Les ancres changent avec la langue (`#verification` devient `#vérification`) : les liens vers une section sont vérifiés dans chaque version.
- Une traduction est fidèle : rien n'est ajouté ni retiré. Un détail manquant est corrigé dans les deux versions.

## 6. Confidentialité et exactitude

- Le seul nom public est **bazeeza**. Les coéquipiers ne sont jamais nommés : écrire « travail réalisé en équipe » (`team work`) ou « un coéquipier » (`a teammate`).
- Le seul contact public est `info@bazeeza.ca`.
- Aucune adresse IP réelle, aucun nom d'hôte, domaine privé, jeton, mot de passe, nom d'employeur ou de site. Utiliser des valeurs génériques comme `<SERVER>`, `contoso.local` ou `192.0.2.10` ([RFC 5737](https://www.rfc-editor.org/rfc/rfc5737)).
- Rien n'est inventé : aucune expérience, aucun résultat, chiffre ou capture qui n'existe pas dans les fichiers. Une procédure générale cite sa source officielle dans la ligne **Référence**.

## 7. Vérification automatique

[`scripts/Test-ReadmePair.ps1`](../scripts/Test-ReadmePair.ps1) vérifie les règles qu'une machine peut contrôler : chaque document bilingue a sa jumelle, les deux fichiers portent les boutons de langue, et chaque lien relatif pointe vers un fichier qui existe. Il est lancé dans le [workflow Markdown](../.github/workflows/markdown.yml) à chaque pull request.

```powershell
# Depuis la racine du dépôt, dans Windows PowerShell 5.1 ou PowerShell 7
.\scripts\Test-ReadmePair.ps1 -Path .
```
