# Linux Backups with restic (and When rsync Is Enough)

![Level](https://img.shields.io/badge/Level-Intermediate-ffb454?style=flat-square)
![Time](https://img.shields.io/badge/Time-30%E2%80%9345%20min-2b9dff?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Debian%20%7C%20Ubuntu%20%7C%20restic%200.14%2B-E95420?style=flat-square)
![Reviewed](https://img.shields.io/badge/Last%20reviewed-2026--10-555?style=flat-square)

| Element | Content |
|---|---|
| **Referent** | A Linux server whose configuration and data must survive a disk failure, a bad change or ransomware. |
| **Sender** | **Bariu Azeez** |
| **Message** | Back up with restic to an encrypted, versioned repository, schedule it with a systemd timer, keep a retention policy, check the repository, and restore to a separate folder to prove it works. |
| **Receiver** | Junior system administrators and technicians responsible for a small server. |
| **Channel** | GitHub repository `Bazeeza/Technical-Runbooks` |
| **Code** | English, technical writing · Linux shell (bash), systemd |
| **Reference** | [restic documentation](https://restic.readthedocs.io/en/stable/) · [restic: Preparing a new repository](https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html) · [restic: Restoring from backup](https://restic.readthedocs.io/en/stable/050_restore.html) · [restic: Removing backup snapshots](https://restic.readthedocs.io/en/stable/060_forget.html) · [systemd.timer(5)](https://www.freedesktop.org/software/systemd/man/latest/systemd.timer.html) · [rsync(1) manual](https://download.samba.org/pub/rsync/rsync.1) |

---

## Objective

Produce, every night, an encrypted copy of the server's important folders that keeps **several past versions**, on another machine, and prove once a month that it restores. This is part of [runbook 13](README.md), which explains the 3-2-1 rule and the restore test record.

## restic or rsync?

| | restic | rsync |
|---|---|---|
| What it produces | Snapshots: every run is a point in time you can go back to | A mirror: the destination looks like the source **now** |
| A file deleted or encrypted by ransomware | Still in the older snapshots | Deleted or encrypted in the copy at the next run (with `--delete`) |
| Encryption | Always (AES-256), with the repository password | None by itself (SSH only protects the transfer) |
| Space used | Deduplicated: unchanged data is stored once | One full copy |
| Good for | Real backups | Moving data, a fast second copy next to a real backup |

rsync alone is a copy, not a backup with history. restic is the tool used below.

## Step 1 — Install restic and create the password file

```bash
sudo apt install restic
restic version
sudo install -d -m 700 /root/.restic
sudo sh -c 'umask 077; openssl rand -base64 32 > /root/.restic/password'
```

The repository password encrypts everything. **Without it, the backup cannot be read by anyone, including you.** Store a copy in the team password manager now, not "later".

**Expected result:** `restic version` prints 0.14 or newer; `/root/.restic/password` is readable by root only (`ls -l` shows `-rw-------`).

## Step 2 — Create the repository on another machine

The repository must not live on the disk it protects. A backup server reached over SFTP (SSH keys, see [runbook 12](../12-Linux-Server-Hardening/README.md)) is the simplest choice:

```bash
sudo tee /root/.restic/env > /dev/null <<'EOF'
RESTIC_REPOSITORY=sftp:backup@<backup-server>:/srv/restic/<this-server>
RESTIC_PASSWORD_FILE=/root/.restic/password
EOF
sudo chmod 600 /root/.restic/env
sudo bash -c 'set -a; . /root/.restic/env; restic init'
```

`restic init` also accepts a local path (an external disk mounted on `/mnt/backup`) or an S3-compatible bucket. The rest of the procedure is the same.

**Expected result:** `created restic repository ... at sftp:...` and a warning to keep the password safe.

## Step 3 — First backup

Back up what cannot be reinstalled from a package: configuration, data, and the list of packages.

```bash
sudo bash -c 'dpkg --get-selections > /root/package-list.txt'
sudo bash -c 'set -a; . /root/.restic/env; restic backup /etc /home /srv /root --exclude-caches --one-file-system --tag nightly'
sudo bash -c 'set -a; . /root/.restic/env; restic snapshots'
```

- `--one-file-system` avoids following mounts (another disk, `/proc`, the backup disk itself).
- `--exclude-caches` skips folders marked as caches.
- A database is backed up from a **dump** (`pg_dump`, `mysqldump`) written to `/srv/backup-dumps` before the run, not by copying its live files, which may be inconsistent.

**Expected result:** a summary with `Files: ... new`, `processed ... files`, and a snapshot ID listed by `restic snapshots`.

## Step 4 — Schedule it with a systemd timer

`/etc/systemd/system/restic-backup.service`:

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

`/etc/systemd/system/restic-backup.timer`:

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

- `Persistent=true`: if the server was off at 02:30, the backup runs at the next boot instead of being skipped.
- The `forget` line keeps 7 daily, 4 weekly and 6 monthly snapshots and deletes the data no snapshot needs any more (`--prune`). Adjust it to the retention the data owner asks for.

**Expected result:** `list-timers` shows the next run; after it, `journalctl -u restic-backup.service` shows the backup summary and `restic snapshots` a new entry.

> [!TIP]
> A backup that fails silently is the worst case. Check `systemctl status restic-backup.service` after the first night, and add an alert (an `OnFailure=` unit that sends a message, or a monitoring check on the age of the last snapshot).

## Step 5 — Check the repository

```bash
sudo bash -c 'set -a; . /root/.restic/env; restic check'
sudo bash -c 'set -a; . /root/.restic/env; restic check --read-data-subset=5%'
```

`restic check` verifies the structure of the repository. `--read-data-subset=5%` also downloads and verifies 5 % of the stored data; over a few months, every part has been read once.

**Expected result:** `no errors were found`.

## Step 6 — Restore test

Restore to a **separate** folder, never over the live data:

```bash
sudo bash -c 'set -a; . /root/.restic/env; restic restore latest --target /tmp/restore-test --include /etc/ssh'
sudo diff -r /etc/ssh /tmp/restore-test/etc/ssh && echo "Restore matches"
```

To get a single file back from an older snapshot:

```bash
sudo bash -c 'set -a; . /root/.restic/env; restic snapshots --path /home'
sudo bash -c 'set -a; . /root/.restic/env; restic restore <snapshot-id> --target /tmp/restore-test --include /home/<user>/report.odt'
```

`diff -r` printing nothing means the restored files are identical to the live ones. A file changed since the backup appears as a difference: compare with a folder that does not change, or note the expected difference in the record.

Fill in the restore test record of [runbook 13](README.md#step-6--record-the-test), then delete `/tmp/restore-test`.

**Expected result:** the restored files open, `diff` reports no unexpected difference, and the time taken is written down.

## rsync: a mirror next to the backup

For a fast second copy of a data folder to a disk or another server:

```bash
rsync -aAXH --delete --dry-run /srv/data/ backup@<backup-server>:/srv/mirror/data/
rsync -aAXH --delete /srv/data/ backup@<backup-server>:/srv/mirror/data/
```

- The **trailing slash** on the source copies its *content*; without it, rsync creates `data/data/`.
- `-aAXH` keeps permissions, ACLs, extended attributes and hard links.
- `--delete` makes the copy an exact mirror, which also mirrors deletions: always run `--dry-run` first and read the list.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `Fatal: wrong password or no key found` | Wrong or missing password file | Check `RESTIC_PASSWORD_FILE` and the copy in the password manager |
| `Fatal: unable to open repository` over SFTP | SSH key not accepted, host key not yet trusted | As root: `ssh backup@<backup-server>` once, accept the host key, check `authorized_keys` on the backup server |
| `unable to create lock` or `repository is already locked` | A previous run was interrupted | Make sure no backup is running (`pgrep restic`), then `restic unlock` |
| Timer never runs | Timer not enabled | `systemctl enable --now restic-backup.timer`, check `list-timers` |
| Restored files owned by root | `restore` run as root keeps the stored owners, or the target is a new system | `ls -ln` to compare numeric IDs; fix with `chown` only on the restored copy |
| Repository grows without limit | `forget` without `--prune` | Add `--prune`, or run `restic prune` |

---

<sub>Part of [runbook 13, Backup and Restore](README.md) · Written by Bariu Azeez</sub>
