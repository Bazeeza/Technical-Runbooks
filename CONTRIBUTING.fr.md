# Contribuer

[![Français](https://img.shields.io/badge/Langue-Français-3fe0a0?style=for-the-badge)](CONTRIBUTING.fr.md)
[![English](https://img.shields.io/badge/Language-English-2b9dff?style=for-the-badge)](CONTRIBUTING.md)

Merci d'aider à garder ces runbooks exacts. Un runbook est suivi par quelqu'un sous pression : une commande fausse coûte du temps réel, chaque correction compte.

## Signaler une erreur

Ouvrez une issue avec le formulaire **[Report an error in a runbook](https://github.com/Bazeeza/Technical-Runbooks/issues/new?template=runbook-error.yml)** (signaler une erreur dans un runbook). Il demande le runbook, l'étape, ce qui s'est passé et, si possible, un lien vers la documentation officielle.

> [!WARNING]
> Ne collez jamais de mots de passe, d'adresses IP internes, de noms d'hôtes, de noms d'utilisateurs ni de captures d'écran qui les montrent. Remplacez-les par des valeurs génériques comme `<SERVER>` ou `192.0.2.10` (une adresse réservée à la documentation, [RFC 5737](https://www.rfc-editor.org/rfc/rfc5737)).

## Proposer un changement

1. Faites une copie (*fork*) du dépôt et créez une branche, par exemple `fix/04-dns-step`.
2. Faites **un seul changement par pull request** (un runbook, ou une correction dans plusieurs runbooks).
3. Vérifiez votre changement en local, puis ouvrez la pull request et décrivez ce que vous avez vérifié.

## Règles d'écriture

| Règle | Pourquoi |
|---|---|
| Suivre le [modèle](TEMPLATE.fr.md) (`TEMPLATE.md`) : tableau d'en-tête, Objectif, Prérequis, Procédure, Vérification, Dépannage, Retour arrière | Un technicien trouve toujours la même section au même endroit |
| Chaque étape donne la commande exacte, **pourquoi** on la lance et le **résultat attendu** | Le lecteur sait tout de suite si l'étape a fonctionné |
| Écrire en anglais, avec vos propres mots | Un texte copié n'est pas accepté comme runbook ; voir [archive/](archive/README.fr.md) pour la façon dont les notes copiées sont traitées |
| Vérifier les commandes dans la documentation officielle des fabricants et la citer dans la ligne **Reference** | Une source permet au lecteur suivant de vérifier, et protège la crédibilité du runbook |
| N'utiliser que des valeurs génériques (`<USERNAME>`, `contoso.local`, `192.0.2.0/24`) | Une documentation publique ne doit jamais exposer un vrai réseau |
| Avertir avant toute étape destructrice et donner un retour arrière | La protection des données passe avant la vitesse |
| Schémas en Mermaid, blocs de code avec un langage (`powershell`, `bash`, `text`) | Les schémas restent modifiables et les commandes sont colorées |

## Scripts

Les scripts PowerShell doivent :

- fonctionner sous **Windows PowerShell 5.1** (celui de Windows 11 par défaut) comme sous PowerShell 7 ;
- prendre en charge `-WhatIf` quand ils modifient le système (`[CmdletBinding(SupportsShouldProcess)]`) ;
- être enregistrés en ASCII, ou en UTF-8 **avec BOM** s'ils contiennent des caractères accentués (Windows PowerShell 5.1 lit un fichier sans BOM comme de l'ANSI) ;
- passer PSScriptAnalyzer avec les paramètres du dépôt :

```powershell
Install-Module PSScriptAnalyzer -Scope CurrentUser
Invoke-ScriptAnalyzer -Path . -Recurse -Settings .\PSScriptAnalyzerSettings.psd1
```

## Vérifications automatiques

Chaque pull request lance les mêmes vérifications que la branche `main` :

| Workflow | Ce qu'il vérifie |
|---|---|
| [Markdown](.github/workflows/markdown.yml) | Les règles markdownlint listées dans [`.markdownlint-cli2.jsonc`](.markdownlint-cli2.jsonc), chaque lien relatif entre fichiers, et les paires de langues du [guide de style](docs/STYLE.fr.md) avec [`Test-ReadmePair.ps1`](scripts/Test-ReadmePair.ps1) |
| [PowerShell](.github/workflows/powershell.yml) | PSScriptAnalyzer (erreurs et avertissements), l'analyse de chaque script par Windows PowerShell 5.1, et les tests Pester de [`scripts/tests/`](scripts/tests/) sous PowerShell 7 et Windows PowerShell 5.1 |
| [External links](.github/workflows/external-links.yml) | Chaque lundi, et à la demande : chaque lien externe répond encore. Pas lancé sur les pull requests, pour qu'un site de fabricant lent ne bloque jamais une correction |

Pour lancer les vérifications Markdown en local (Node.js nécessaire) :

```bash
npx markdownlint-cli2 "**/*.md"
```

Pour vérifier les paires de langues et lancer les tests des scripts en local (Pester 5 nécessaire) :

```powershell
.\scripts\Test-ReadmePair.ps1 -Path .
Install-Module Pester -MinimumVersion 5.5.0 -Scope CurrentUser -SkipPublisherCheck
Invoke-Pester -Path .\scripts\tests -Output Detailed
```

## Traductions

Chaque runbook est écrit en anglais (`X.md`) et reçoit une jumelle en français (`X.fr.md`). Le [guide de style de la documentation](docs/STYLE.fr.md) donne les règles : les boutons de langue sous le titre, les mêmes sections, liens et commandes dans les deux versions, et le code, les commandes et les noms de fichiers jamais traduits. Un changement dans une version est fait dans l'autre dans la même pull request.

## Journal des modifications

Les changements notables sont listés dans le [journal des modifications](CHANGELOG.fr.md) (`CHANGELOG.md`). Ajoutez une ligne sous **Unreleased** dans votre pull request.
