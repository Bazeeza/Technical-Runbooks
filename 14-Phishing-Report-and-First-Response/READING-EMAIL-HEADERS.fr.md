# Lire les en-têtes d'un courriel suspect

[![Français](https://img.shields.io/badge/Langue-Français-3fe0a0?style=for-the-badge)](READING-EMAIL-HEADERS.fr.md)
[![English](https://img.shields.io/badge/Language-English-2b9dff?style=for-the-badge)](READING-EMAIL-HEADERS.md)

![Level](https://img.shields.io/badge/Level-Intermediate-ffb454?style=flat-square)
![Time](https://img.shields.io/badge/Time-10%20min-2b9dff?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Outlook%20%7C%20Microsoft%20365-0078D6?style=flat-square)
![Reviewed](https://img.shields.io/badge/Last%20reviewed-2026--11-555?style=flat-square)

| Élément | Contenu |
|---|---|
| **Référent** | Les en-têtes Internet d'un courriel : les lignes cachées qui indiquent qui l'a envoyé, par quels serveurs il est passé et si le domaine de l'expéditeur s'en est porté garant. |
| **Émetteur** | **bazeeza** |
| **Message** | Copier les en-têtes sans toucher aux liens ni aux pièces jointes, lire les adresses From, Reply-To et Return-Path, les résultats SPF, DKIM, DMARC et compauth, et la chaîne Received, puis inscrire les signaux d'alerte dans le billet. |
| **Récepteur** | Techniciens de soutien TI à qui l'on demande « ce courriel est-il vrai ? ». |
| **Canal** | Dépôt GitHub `Bazeeza/Technical-Runbooks` |
| **Code** | Français, rédaction technique (traduction de l'original anglais) · Windows PowerShell 5.1 |
| **Référence** | [Microsoft Learn: Anti-spam message headers](https://learn.microsoft.com/en-us/defender-office-365/message-headers-eop-mdo) · [Microsoft Support: View internet message headers in Outlook](https://support.microsoft.com/office/cd039382-dc6e-4264-ac74-c048563d212c) · [RFC 5322, Internet Message Format](https://www.rfc-editor.org/rfc/rfc5322) · [Canadian Centre for Cyber Security: Spotting malicious e-mail messages (ITSAP.00.100)](https://www.cyber.gc.ca/en/guidance/spotting-malicious-email-messages-itsap00100) |

Retour à [14 Signalement d'hameçonnage et première intervention](README.fr.md).

---

## Pourquoi les en-têtes comptent

Le nom et l'adresse affichés dans la liste des messages sont écrits par l'expéditeur : ils peuvent donc dire n'importe quoi. Les en-têtes sont ajoutés par les **serveurs de messagerie** en cours de route, et la ligne `Authentication-Results` est écrite par le système de messagerie destinataire après qu'il a vérifié le domaine de l'expéditeur. Les lire répond à deux questions avec des faits plutôt qu'avec des impressions :

1. Le message vient-il vraiment du domaine qu'il prétend ?
2. Si quelqu'un répond, où va la réponse ?

> [!WARNING]
> Travaillez seulement sur les **en-têtes**. Ne cliquez sur aucun lien, n'ouvrez aucune pièce jointe, ne scannez aucun code QR et ne répondez pas, même « pour tester ». Pour savoir où mène un lien, survolez-le et lisez l'adresse affichée au bas de la fenêtre, ou laissez l'équipe de sécurité l'analyser.

## Étape 1 — Copier les en-têtes

| Client | Chemin |
|---|---|
| Outlook classique pour Windows | Double-cliquez sur le message pour l'ouvrir dans sa propre fenêtre › **File** › **Properties** › la zone **Internet headers**. Tout sélectionner, copier. |
| Nouvel Outlook pour Windows | Ouvrez le message › **More actions** (`...`) › **View** › **View message details**. Copier. |
| Outlook sur le web | **More actions** (`...`) › **View** › **View message details**. Copier. |

Collez le texte dans le Bloc-notes et enregistrez-le sous `headers.txt` dans le dossier du billet. Un fichier `.eml` enregistré fonctionne aussi.

**Résultat attendu :** un fichier texte qui commence par plusieurs lignes `Received:` et contient `From:`, `Subject:` et, dans Microsoft 365, `Authentication-Results:`.

## Étape 2 — Lancer le script de résumé

[`Get-EmailHeaderSummary.ps1`](Get-EmailHeaderSummary.ps1) lit seulement le bloc des en-têtes (il s'arrête à la première ligne vide), ne se connecte jamais au réseau et liste les signaux d'alerte en langage clair.

```powershell
.\Get-EmailHeaderSummary.ps1 -Path .\headers.txt | Format-List
.\Get-EmailHeaderSummary.ps1 -Path .\headers.txt | Select-Object -ExpandProperty Hops | Format-Table
```

Pour vous exercer, lancez-le sur le fichier fictif [`sample-headers-suspicious.txt`](sample-headers-suspicious.txt) : il doit signaler un SPF en échec partiel (softfail), aucune signature DKIM, aucun enregistrement DMARC, `compauth=fail`, un Reply-To dans un autre domaine et un nom affiché qui se fait passer pour une adresse interne.

Le [Message Header Analyzer](https://mha.azurewebsites.net/) de Microsoft donne les mêmes informations dans une page web. N'y collez des en-têtes que si votre organisation le permet, car ils contiennent des noms et des adresses de serveurs internes.

**Résultat attendu :** les champs de l'expéditeur, les résultats d'authentification, la liste des sauts et une liste **Findings** (constats).

## Étape 3 — Comparer les trois adresses d'expéditeur

| En-tête | Qui l'écrit | Quoi vérifier |
|---|---|---|
| `From:` | L'expéditeur (affiché à l'utilisateur) | Nom affiché et vraie adresse : `"IT Support" <it-support@contoso-helpdesk.example>` n'est **pas** `contoso.com`. Cherchez des mots ajoutés, des lettres interverties (`rn` pour `m`) ou un autre domaine de premier niveau. |
| `Reply-To:` | L'expéditeur | Les réponses vont ici. Un Reply-To dans un autre domaine que le From est un signe classique de vol d'identifiants ou de fraude à la facture. |
| `Return-Path:` | Le serveur d'envoi (expéditeur de l'enveloppe, `5321.MailFrom`) | Les retours de non-livraison vont ici, et SPF vérifie ce domaine. Les services d'envoi en masse utilisent souvent leur propre domaine ici : une différence est donc normale **seulement** quand SPF, DKIM et DMARC réussissent. |

## Étape 4 — Lire les résultats d'authentification

Le premier en-tête `Authentication-Results` (le plus haut) est ajouté par le système destinataire : c'est celui auquel se fier. Ceux plus bas peuvent avoir été écrits par l'expéditeur.

| Vérification | Question à laquelle elle répond | Résultats à noter |
|---|---|---|
| **SPF** | Le serveur d'envoi a-t-il le droit d'envoyer pour le domaine `smtp.mailfrom` ? | `pass` est bon. `fail` (`-all`) et `softfail` (`~all`) signifient que le serveur n'est pas dans la liste ; `none` signifie que le domaine ne publie aucun enregistrement SPF. |
| **DKIM** | Le message est-il signé par le domaine de `header.d`, et inchangé depuis ? | `pass` est bon. `none` signifie non signé ; `fail` signifie que la signature ne correspond pas. |
| **DMARC** | Un SPF ou un DKIM réussi est-il **aligné** sur le domaine `From:` que voit l'utilisateur ? | `pass` (ou `bestguesspass` quand le domaine n'a pas d'enregistrement DMARC) est bon. `fail` avec un domaine From auquel l'utilisateur fait confiance signifie une usurpation. `none` signifie aucun enregistrement DMARC. |
| **compauth** | Le verdict global de Microsoft 365 sur l'adresse From | `pass` ou `softpass` est bon ; `fail` (avec un code `reason`) signifie que Microsoft 365 n'a pas pu confirmer l'expéditeur. |

Des vérifications réussies prouvent seulement que le message vient du domaine de l'adresse From, **pas** que ce domaine est honnête : un attaquant peut enregistrer `contoso-helpdesk.example` et réussir SPF, DKIM et DMARC pour ce domaine. Lisez toujours le domaine lui-même.

L'en-tête `X-Forefront-Antispam-Report` montre comment Microsoft 365 a classé le message : `CAT:PHSH` est de l'hameçonnage, `CAT:SPOOF` une usurpation, `SFV:SPM` du pourriel, `SFV:SFE` un message livré parce que l'expéditeur figurait dans la liste des expéditeurs approuvés (Safe Senders) de l'utilisateur.

## Étape 5 — Suivre la chaîne Received

Chaque serveur ajoute une ligne `Received:` **au-dessus** des autres : lisez-les donc de bas en haut pour aller de l'origine à la boîte aux lettres. Le script le fait pour vous (`Hops`, le saut 1 est l'origine).

- Le premier saut montre le serveur qui a vraiment envoyé le message : son nom appartient-il à l'expéditeur prétendu ?
- Les dates doivent avancer de quelques secondes ou minutes. Un écart de plusieurs heures ou une date dans le futur indique une ligne falsifiée ou retardée.

## Étape 6 — Inscrire les constats dans le billet

```text
Suspicious e-mail analysis
Reported by / time      :
Subject                 :
From (display / address):
Reply-To / Return-Path  :
SPF / DKIM / DMARC      :
compauth / CAT          :
Origin server (hop 1)   :
Red flags               :
Other recipients        : (same subject or sender in other mailboxes, if known)
User action             : none / clicked / entered credentials / opened attachment
Headers file attached   : yes
```

Continuez ensuite avec la [liste de vérification de première intervention](FIRST-RESPONSE-CHECKLIST.fr.md) selon l'action de l'utilisateur.

---

## Dépannage

| Symptôme | Cause probable | Correction |
|---|---|---|
| Le script affiche « No header found » | Seul le corps a été copié, ou le fichier commence par une ligne vide issue du collage | Recopier depuis **Internet headers** ou **View message details** ; le fichier doit commencer par `Received:` ou un autre en-tête |
| Aucune ligne `Authentication-Results` | Message transféré par l'utilisateur (nouveaux en-têtes), ou message interne | Demander à l'utilisateur de signaler l'original avec le bouton **Report** plutôt que de le transférer |
| Tout réussit mais le message est clairement faux | L'attaquant utilise un domaine sosie qui lui appartient | Le signaler quand même : l'authentification prouve le domaine, pas l'intention |
| Infolettre légitime avec un Return-Path différent | Service d'envoi en masse qui envoie au nom de l'entreprise | Normal quand SPF, DKIM et DMARC réussissent |

---

<sub>Écrit par bazeeza · Vous avez trouvé une erreur ? <a href="https://github.com/Bazeeza/Technical-Runbooks/issues/new?template=runbook-error.yml">Signalez-la ici</a>.</sub>
