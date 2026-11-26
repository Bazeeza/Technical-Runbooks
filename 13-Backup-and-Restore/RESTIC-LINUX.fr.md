# Sauvegardes Linux avec restic (et quand rsync suffit)

[![Français](https://img.shields.io/badge/Langue-Français-3fe0a0?style=for-the-badge)](RESTIC-LINUX.fr.md)
[![English](https://img.shields.io/badge/Language-English-2b9dff?style=for-the-badge)](RESTIC-LINUX.md)

![Level](https://img.shields.io/badge/Level-Intermediate-ffb454?style=flat-square)
![Time](https://img.shields.io/badge/Time-30%E2%80%9345%20min-2b9dff?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Debian%20%7C%20Ubuntu%20%7C%20restic%200.14%2B-E95420?style=flat-square)
![Reviewed](https://img.shields.io/badge/Last%20reviewed-2026--10-555?style=flat-square)

| Élément | Contenu |
|---|---|
| **Référent** | Un serveur Linux dont la configuration et les données doivent survivre à une panne de disque, à une mauvaise modification ou à un rançongiciel. |
| **Émetteur** | **bazeeza** |
| **Message** | Sauvegarder avec restic vers un dépôt chiffré et versionné, planifier avec un minuteur systemd, appliquer une politique de rétention, vérifier le dépôt, et restaurer dans un dossier séparé pour prouver que tout fonctionne. |
| **Récepteur** | Administrateurs système débutants et techniciens responsables d'un petit serveur. |
| **Canal** | Dépôt GitHub `Bazeeza/Technical-Runbooks` |
| **Code** | Français, rédaction technique (traduction de l'original anglais) · shell Linux (bash), systemd |
| **Référence** | [restic documentation](https://restic.readthedocs.io/en/stable/) · [restic: Preparing a new repository](https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html) · [restic: Restoring from backup](https://restic.readthedocs.io/en/stable/050_restore.html) · [restic: Removing backup snapshots](https://restic.readthedocs.io/en/stable/060_forget.html) · [systemd.timer(5)](https://www.freedesktop.org/software/systemd/man/latest/systemd.timer.html) · [rsync(1) manual](https://download.samba.org/pub/rsync/rsync.1) |

---

## Objectif

Produire chaque nuit, sur une autre machine, une copie chiffrée des dossiers importants du serveur qui garde **plusieurs versions passées**, et prouver une fois par mois qu'elle se restaure. Ce guide fait partie du [runbook 13](README.fr.md), qui explique la règle 3-2-1 et le registre des tests de restauration.

## restic ou rsync ?

| | restic | rsync |
|---|---|---|
| Ce qu'il produit | Des instantanés : chaque exécution est un point dans le temps auquel on peut revenir | Un miroir : la destination ressemble à la source **maintenant** |
| Un fichier supprimé ou chiffré par un rançongiciel | Toujours présent dans les instantanés plus anciens | Supprimé ou chiffré dans la copie à l'exécution suivante (avec `--delete`) |
| Chiffrement | Toujours (AES-256), avec le mot de passe du dépôt | Aucun par lui-même (SSH ne protège que le transfert) |
| Espace utilisé | Dédupliqué : les données inchangées sont stockées une seule fois | Une copie complète |
| Bon pour | Les vraies sauvegardes | Déplacer des données, une deuxième copie rapide à côté d'une vraie sauvegarde |

rsync seul est une copie, pas une sauvegarde avec historique. restic est l'outil utilisé ci-dessous.

## Étape 1 — Installer restic et créer le fichier de mot de passe

```bash
sudo apt install restic
restic version
sudo install -d -m 700 /root/.restic
sudo sh -c 'umask 077; openssl rand -base64 32 > /root/.restic/password'
```

Le mot de passe du dépôt chiffre tout. **Sans lui, personne ne peut lire la sauvegarde, vous y compris.** Conservez-en une copie dans le gestionnaire de mots de passe de l'équipe maintenant, pas « plus tard ».

**Résultat attendu :** `restic version` affiche 0.14 ou plus récent ; `/root/.restic/password` n'est lisible que par root (`ls -l` affiche `-rw-------`).

## Étape 2 — Créer le dépôt sur une autre machine

Le dépôt ne doit pas se trouver sur le disque qu'il protège. Un serveur de sauvegarde joint par SFTP (clés SSH, voir le [runbook 12](../12-Linux-Server-Hardening/README.fr.md)) est le choix le plus simple :

```bash
sudo tee /root/.restic/env > /dev/null <<'EOF'
RESTIC_REPOSITORY=sftp:backup@<backup-server>:/srv/restic/<this-server>
RESTIC_PASSWORD_FILE=/root/.restic/password
EOF
sudo chmod 600 /root/.restic/env
sudo bash -c 'set -a; . /root/.restic/env; restic init'
```

`restic init` accepte aussi un chemin local (un disque externe monté sur `/mnt/backup`) ou un compartiment compatible S3. Le reste de la procédure est identique.

**Résultat attendu :** `created restic repository ... at sftp:...` et un avertissement demandant de garder le mot de passe en lieu sûr.

## Étape 3 — Première sauvegarde

Sauvegarder ce qui ne peut pas être réinstallé à partir d'un paquet : la configuration, les données et la liste des paquets.

```bash
sudo bash -c 'dpkg --get-selections > /root/package-list.txt'
sudo bash -c 'set -a; . /root/.restic/env; restic backup /etc /home /srv /root --exclude-caches --one-file-system --tag nightly'
sudo bash -c 'set -a; . /root/.restic/env; restic snapshots'
```

- `--one-file-system` évite de suivre les points de montage (un autre disque, `/proc`, le disque de sauvegarde lui-même).
- `--exclude-caches` ignore les dossiers marqués comme caches.
- Une base de données se sauvegarde à partir d'une **copie** (*dump* : `pg_dump`, `mysqldump`) écrite dans `/srv/backup-dumps` avant l'exécution, pas en copiant ses fichiers en service, qui peuvent être incohérents.

**Résultat attendu :** un résumé avec `Files: ... new`, `processed ... files`, et un identifiant d'instantané listé par `restic snapshots`.

## Étape 4 — Planifier avec un minuteur systemd

`/etc/systemd/system/restic-backup.service` :

```ini
[Unit]
Description=restic backup of /etc /home /srv /root
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
EnvironmentFile=/root/.restic/env
ExecStartPre=/bin/sh -c 'dpkg --get-selections > /root/package-list.txt'
ExecStart=/usr/bin/restic backup /etc /home /srv /root --exclude-caches --one-file-system --tag nightly
ExecStartPost=/usr/bin/restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune
```

`/etc/systemd/system/restic-backup.timer` :

```ini
[Unit]
Description=Nightly restic backup

[Timer]
OnCalendar=*-*-* 02:30:00
RandomizedDelaySec=30m
Persistent=true

[Install]
WantedBy=timers.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now restic-backup.timer
systemctl list-timers restic-backup.timer
```

- `Persistent=true` : si le serveur était éteint à 2 h 30, la sauvegarde s'exécute au démarrage suivant au lieu d'être sautée.
- La ligne `forget` garde 7 instantanés quotidiens, 4 hebdomadaires et 6 mensuels, et supprime les données dont plus aucun instantané n'a besoin (`--prune`). L'ajuster à la rétention demandée par le responsable des données.

**Résultat attendu :** `list-timers` affiche la prochaine exécution ; après celle-ci, `journalctl -u restic-backup.service` affiche le résumé de la sauvegarde et `restic snapshots` une nouvelle entrée.

> [!TIP]
> Une sauvegarde qui échoue en silence est le pire des cas. Vérifier `systemctl status restic-backup.service` après la première nuit, et ajouter une alerte (une unité `OnFailure=` qui envoie un message, ou une vérification de supervision sur l'âge du dernier instantané).

## Étape 5 — Vérifier le dépôt

```bash
sudo bash -c 'set -a; . /root/.restic/env; restic check'
sudo bash -c 'set -a; . /root/.restic/env; restic check --read-data-subset=5%'
```

`restic check` vérifie la structure du dépôt. `--read-data-subset=5%` télécharge et vérifie aussi 5 % des données stockées ; en quelques mois, chaque partie a été lue une fois.

**Résultat attendu :** `no errors were found`.

## Étape 6 — Test de restauration

Restaurer dans un dossier **séparé**, jamais par-dessus les données en service :

```bash
sudo bash -c 'set -a; . /root/.restic/env; restic restore latest --target /tmp/restore-test --include /etc/ssh'
sudo diff -r /etc/ssh /tmp/restore-test/etc/ssh && echo "Restore matches"
```

Pour récupérer un seul fichier d'un instantané plus ancien :

```bash
sudo bash -c 'set -a; . /root/.restic/env; restic snapshots --path /home'
sudo bash -c 'set -a; . /root/.restic/env; restic restore <snapshot-id> --target /tmp/restore-test --include /home/<user>/report.odt'
```

Si `diff -r` n'affiche rien, les fichiers restaurés sont identiques aux fichiers en service. Un fichier modifié depuis la sauvegarde apparaît comme une différence : comparer avec un dossier qui ne change pas, ou noter la différence attendue dans le registre.

Remplir le registre du test de restauration du [runbook 13](README.fr.md#étape-6--consigner-le-test), puis supprimer `/tmp/restore-test`.

**Résultat attendu :** les fichiers restaurés s'ouvrent, `diff` ne signale aucune différence inattendue, et la durée est notée.

## rsync : un miroir à côté de la sauvegarde

Pour une deuxième copie rapide d'un dossier de données vers un disque ou un autre serveur :

```bash
rsync -aAXH --delete --dry-run /srv/data/ backup@<backup-server>:/srv/mirror/data/
rsync -aAXH --delete /srv/data/ backup@<backup-server>:/srv/mirror/data/
```

- La **barre oblique finale** sur la source copie son *contenu* ; sans elle, rsync crée `data/data/`.
- `-aAXH` conserve les permissions, les ACL, les attributs étendus et les liens physiques.
- `--delete` fait de la copie un miroir exact, qui reproduit donc aussi les suppressions : toujours lancer `--dry-run` d'abord et lire la liste.

## Dépannage

| Symptôme | Cause probable | Correction |
|---|---|---|
| `Fatal: wrong password or no key found` | Fichier de mot de passe erroné ou absent | Vérifier `RESTIC_PASSWORD_FILE` et la copie dans le gestionnaire de mots de passe |
| `Fatal: unable to open repository` en SFTP | Clé SSH refusée, clé d'hôte pas encore approuvée | En root : `ssh backup@<backup-server>` une fois, accepter la clé d'hôte, vérifier `authorized_keys` sur le serveur de sauvegarde |
| `unable to create lock` ou `repository is already locked` | Une exécution précédente a été interrompue | S'assurer qu'aucune sauvegarde n'est en cours (`pgrep restic`), puis `restic unlock` |
| Le minuteur ne s'exécute jamais | Minuteur non activé | `systemctl enable --now restic-backup.timer`, vérifier `list-timers` |
| Fichiers restaurés appartenant à root | `restore` lancé en root conserve les propriétaires stockés, ou la cible est un nouveau système | `ls -ln` pour comparer les identifiants numériques ; corriger avec `chown` seulement sur la copie restaurée |
| Le dépôt grossit sans limite | `forget` sans `--prune` | Ajouter `--prune`, ou lancer `restic prune` |

---

<sub>Fait partie du [runbook 13, Sauvegarde et restauration](README.fr.md) · Écrit par bazeeza</sub>
