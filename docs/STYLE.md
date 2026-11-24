# Documentation Style Guide

[![Français](https://img.shields.io/badge/Langue-Français-3fe0a0?style=for-the-badge)](STYLE.fr.md)
[![English](https://img.shields.io/badge/Language-English-2b9dff?style=for-the-badge)](STYLE.md)

| Item | Details |
|---|---|
| Goal | Make every README and document of the `Bazeeza` repositories bilingual, easy to scan and consistent |
| Technologies | Markdown (GitHub Flavored), shields.io badges, Mermaid, PowerShell 5.1 for the automatic check |
| Level | Beginner |
| Contents | Language buttons, the "at a glance" table, the repository tree, the visual style, translation and privacy rules |
| Status | In progress |
| Start here | [1. Language buttons](#1-language-buttons) |

This guide applies to the `README.md` files and the other `.md` documents of the repositories. It completes the [runbook template](../TEMPLATE.md), which describes the **inside** of a runbook (objective, procedure, verification, rollback); this guide describes what surrounds it: the language, the first screen and the presentation.

> [!NOTE]
> **Golden rule: add, do not change.** Existing text, files, folders and links stay as they are. A translation, a table or a tree is **added**. The only exceptions are the removal of personal names and the reorganization of a README that is hard to read, without losing any information.

---

## 1. Language buttons

GitHub does not run JavaScript in a README, so the language switch is made of two clickable shields.io badges, placed on the **first line under the title**, without emoji:

```markdown
[![Français](https://img.shields.io/badge/Langue-Français-3fe0a0?style=for-the-badge)](README.fr.md)
[![English](https://img.shields.io/badge/Language-English-2b9dff?style=for-the-badge)](README.md)
```

| Original language of the document | Name of the original | Name of the translation |
|---|---|---|
| English (Technical-Runbooks, helpdesk-toolkit, homelab-infrastructure, thm-badge-finder) | `X.md` | `X.fr.md` |
| French (Projets-Runbooks, webdingo-noc-lab) | `X.md` | `X.en.md` |

- The original language of a document **never changes**: `X.md` stays the original, the twin gets the language suffix.
- Both buttons appear in **both** files, in the same order (French first, English second). Each button points to the file in its language, so the reader can always switch back.
- The links of a translated document point to the translated documents when they exist (`../04-Network-Troubleshooting/README.fr.md`), otherwise to the original.

## 2. The "at a glance" table

Right after the buttons, a six-row table tells the reader in ten seconds what the folder is about:

| French | English | What to write |
|---|---|---|
| Élément \| Contenu | Item \| Details | Header row |
| Objectif | Goal | One sentence: what the project or document lets you do |
| Technologies | Technologies | The tools really used, read in the files |
| Niveau | Level | Beginner, Intermediate or Advanced |
| Contenu | Contents | What the folder holds: procedure, scripts, diagrams, results |
| Statut | Status | Completed, In progress or Archived |
| Lire en premier | Start here | Link to the most useful file |

> [!IMPORTANT]
> Only **verifiable** rows. When a value cannot be read in the files (for example the status of an old course project), the row is removed, never guessed.

Runbooks already open with their own header table (Referent, Sender, Message...). They keep it: the "at a glance" table is added to the README files of repositories, courses and projects, not inside each runbook.

## 3. The repository tree

The root README of each repository, and the README of each course or project folder, shows the **real** tree in a `text` block, read from the disk, with a one-line comment per folder. Excerpt of this repository:

```text
Technical-Runbooks/
├── 01-PC-Boot-Process-and-BIOS-UEFI/   Boot stages, firmware settings, no-boot repair
├── 02-Windows-11-Clean-Installation/   Clean install and post-installation checklist
├── docs/                               Style guide (this file)
├── scripts/                            Repository checks (Test-ReadmePair.ps1)
└── TEMPLATE.md                         Template for a new runbook
```

Under the tree, a table or a list gives a link to every sub-README, because links do not work inside a code block. The French tree uses French comments, the English tree English comments; folder and file names are never translated.

## 4. A document people want to read

| Element | Rule |
|---|---|
| Title | Centered on a repository README (`<h1 align="center">`), plain `#` heading in other documents |
| Hook | One sentence under the title that says what the reader gains |
| Badges | shields.io, `flat-square` style for information, `for-the-badge` only for the language buttons |
| Colours | `#3fe0a0` green, `#2b9dff` blue, `#ffb454` orange, `#c792ea` purple, on a `#070d1c` background in diagrams |
| Sections | Short, one idea each, with a table when several items are compared |
| Call-outs | `> [!NOTE]`, `> [!TIP]`, `> [!IMPORTANT]`, `> [!WARNING]` for what must not be missed |
| Diagrams | Mermaid when the files allow it to be drawn without inventing anything |
| Navigation | In a series, a footer `← Previous · Contents · Next →` (`← Précédent · Sommaire · Suivant →` in French) |
| Emoji | None in public texts: screen readers announce them one by one and they render differently on each platform |

Mermaid rules that avoid rendering errors on GitHub:

- a label never starts with a number followed by a dot (`1. Install` is read as a list): write `Step 1 - Install`;
- labels that contain parentheses, slashes or colons are quoted: `A["Server (AWS)"]`;
- `classDef` uses the colours above, for example `classDef network fill:#070d1c,stroke:#2b9dff,color:#2b9dff`.

## 5. Translation rules

| Translated | Never translated |
|---|---|
| Titles, paragraphs, table text, comments in trees, alt text of images | Code, commands, parameters, file and folder names, terminal output, configuration files, product names |

- Both versions have **the same sections in the same order, the same links and the same commands**. A change to one version is made to the other on the same day.
- Anchors change with the language (`#verification` becomes `#vérification`): links to a section are checked in each version.
- A translation is faithful: nothing is added or removed. A missing detail is fixed in both versions.

## 6. Privacy and accuracy

- The only public name is **bazeeza**. Teammates are never named: write "team work" (`travail réalisé en équipe`) or "a teammate" (`un coéquipier`).
- The only public contact is `info@bazeeza.ca`.
- No real IP address, host name, private domain, token, password, employer or site name. Use placeholders such as `<SERVER>`, `contoso.local` or `192.0.2.10` ([RFC 5737](https://www.rfc-editor.org/rfc/rfc5737)).
- Nothing is invented: no experience, result, figure or screenshot that does not exist in the files. A general procedure cites its official source in the **Reference** row.

## 7. Automatic check

[`scripts/Test-ReadmePair.ps1`](../scripts/Test-ReadmePair.ps1) checks the rules that a machine can verify: every bilingual document has its twin, both files carry the language buttons, and every relative link points to an existing file. It runs in the [Markdown workflow](../.github/workflows/markdown.yml) on every pull request.

```powershell
# From the root of the repository, in Windows PowerShell 5.1 or PowerShell 7
.\scripts\Test-ReadmePair.ps1 -Path .
```
