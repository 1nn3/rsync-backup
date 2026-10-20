# Rsync Backup Workflow

## Checklist

1. Integritätscheck und Backup erstellen
2. System aktualisieren und Konfiguration vornehmen
3. Erneuter Integritätscheck (und Backup) um die Daten für den nächsten Zyklus zu haben
4. Lokales Backup erstellen usw.

## Backup your data

```
find
./server-backup
./server-backup/data
./server-backup/Makefile
./server-backup/README.txt
./server-backup/.rsync-backup
./server-backup/.rsync-backup/rsync-filter
./server-backup/.tripwire-wrapper
./server-backup/.tripwire-wrapper/twcfg.txt
./server-backup/.tripwire-wrapper/twpol.txt
cat server-backup/Makefile
all: check
check: rsync_backup
	@tripwire-wrapper --check
test: rsync_backup
	@tripwire-wrapper --test
update: rsync_backup
	@tripwire-wrapper --update
rsync_backup:
	@rsync-backup --src root@server:/ --dest data -- --chown=$(USER):$(USER)
```

## Restore

### UUID ändern/anpassen

```
uuidgen # UUID ggf. erstellen
```

EXT-Partitionen:

```
tune2fs -U <UUID> <device> # UUID eines Dateisystems ändern
```

Swap-Partitionen:

```
swapoff -v <device>
mkswap -U <UUID> <device>
swapon -v <device>
```

Verschlüsselte cryptsetup/LUKS Partitionen:

```
cryptsetup luksUUID <device> --uuid <UUID>
```

RAID-Partitionen:

```
mdadm --assemble <device> --update=uuid --uuid <UUID>
```

## Zentrale Paketverwaltung für viele Rechner mit Ansible

### Ansible installieren

```
apt install ansible
```

Ansonsten kann ansible auch über Python mittels PIP installiert werden: `pip install ansible`

### Das Inventory

```
cat <<! > ~/ansible/inventory.ini
# inventory.ini
# Liste von Servern auf denen die Aktualisierungen installiert werden sollen
# Usage:
# cd ~/ansible
# source env/bin/activate
# ansible-playbook -i inventory.ini playbook.yml
[all:vars]
	ansible_connection=ssh
	ansible_ssh_user=root
[hosts]
	192.168.1.2 ansible_ssh_pass=secret
	192.168.1.3 ansible_ssh_pass=secret
	192.168.1.4 ansible_ssh_pass=secret
	192.168.1.5 ansible_ssh_pass=secret
!
```

### Das Playbook

```
cat <<! > ~/ansible/upgrade.yml 
#!/usr/bin/env ansible-playbook
- hosts: all
  tasks:
  - name: Backup and Intrusion Detection check
    local_action: command /usr/local/bin/backup-and-intrusion-detection-script check {{inventory_hostname}}
  - name: Upgrade all packages to the latest version
    shell: service iwatch stop
    apt:
      force_apt_get: True
      name: "*"
      state: latest
      update_cache: yes
    shell: service iwatch start
  - name: Backup and Tripwire update
    local_action: command /usr/local/bin/backup-and-intrusion-detection-script update {{inventory_hostname}}
!
chmod +x ~/ansible/playbook.yml
```

Um Pakete zu installieren, kann man das Playbook entsprechend um einen Task erweitern. Das local_action command ist hier nur ein Beispiel und muss sonst entfernt werden.

### Ansible über einen SOCKS-Proxy ausführen

Benutzerdefinierte SSH-Konfigurationsdateien sind:

*~/ansible/ssh_config*:

```
Host *
	ProxyCommand /usr/bin/nc -x 127.0.0.1:1080 %h %p
```

*~/ansible/inventory.ini*:

```
[all:vars]
	ansible_ssh_common_args=-F ssh_config
```

## Rsync daemon setup

```
cat <<! > /etc/rsyncd.conf 
motd file = /etc/rsyncd.motd
log file = /var/log/rsyncd.log
pid file = /var/run/rsyncd.pid
lock file = /var/run/rsync.lock
hosts allow = 192.168.122.0/24
transfer logging = true
log format = %h %o %f %l %b
use chroot = true
[rsnapshot]
	path = /rsnapshot-backups
	comment = Rsync backup (rsnapshot)
	read only = no
	list = yes
	uid = root
	gid = root
!
service rsync restart
```

Da ein privilegierter Port (873) genutzt wird, muss der Rsync daemon mit Root-Rechten gestartet werden:

```
sudo rsync --config=/etc/rsyncd.conf --daemon --no-detach 
```

Verbindung testen

```
rsync -rdt rsync://192.168.122.1
```

Pull:

```
rsync [optionen] rsync://user@192.168.122.1[:PORT][SRC…] [DEST]
```
Push:

```
rsync [optionen] [SRC…] rsync://user@192.168.122.1[:PORT][DEST]
```

```
rsync-backup -d rsync://192.168.122.1/[DEST]
```

## rsnapshot

```
apt install rsnapshot rsync cron openssh-client
dpkg -l rsnaphot
rsnapshot --version
```

```
cat <<! >/etc/rsnapshot.conf
config_version	1.2
cmd_rsync	/usr/bin/rsync
cmd_ssh		/usr/bin/ssh
# Backup destination (must end with /)
snapshot_root	/rsnapshot-backup/
# Retention policy
retain		hourly	8
retain		daily	7
retain		weekly	4
retain		monthly	6
retain		yearly	1
# Preserve file attributes
verbose		2
loglevel	3
logfile		/var/log/rsnapshot.log
lockfile	/var/run/rsnapshot.pid
# Backup local directories
backup	/etc/		localhost/
backup	/usr/local/	localhost/
backup	/var/local/	localhost/
backup	/srv/		localhost/
!
```

**Hinweis:** In rsnapshot.conf müssen die Felder durch Tabs getrennt werden, nicht durch Leerzeichen.

```
rsnapshot configtest
rsnapshot -t hourly
```

## FAQ

### How to debug?

Run ``sh -x path/to/script for xtrace`.

### Festplatte mit cryptsetup/LUKS verschlüsseln und mittels Keyfile einhängen

```
# Benchmarks ciphers and KDF (key derivation function)
# Without parameters, it tries to measure few common configurations
cryptsetup benchmark
```

```
# Partitionieren
cfdisk <device>
blockdev --rereadpt <device>
# Verschlüsselung einrichten
luksformat -t ext4 /dev/sdb1
# Keyfile erstellen und entschlüsseln
dd if=/dev/urandom of=/root/sdb1.luksKeyFile bs=1 count=4096
cryptsetup luksAddKey /dev/sdb1 /root/sdb1.luksKeyFile
# einhängen in fstab(5) und crypttab(5)
cat <<! >>/etc/crypttab
sdb1_crypt UUID=<insert uuid of /dev/sdb1> /root/sdb1.luksKeyFile luks,discard
!
cat <<! >>/etc/fstab
/dev/mapper/sdb1_crypt /srv ext4 errors=remount-ro 0 1
!
# set the reserved-blocks-percentage to zero
tune2fs -m 0 /dev/mapper/sdb1_crypt
```

### cryptsetup/LUKS Passphrase oder Keyfile ändern

```
cryptsetup luksChangeKey <device> [<new key file>] # its interactively
```

### Eine mit cryptsetup/LUKS verschlüsselte Festplatte einhängen

```
# einhängen
cryptsetup luksOpen /dev/sdb1 sdb1_crypt
mount /dev/mapper/sdb1_crypt /mnt
```

```
# aushängen
umount /mnt
cryptsetup close sdb1_crypt
```

### Die cryptsetup/LUKS-Passphrase ändern

```
cryptsetup luksChangeKey /dev/sdb1
```

Gib zuerst das aktuelles Passwort ein und anschließend das neue Passwort, das bestätigt werden muss.

### Wenn man mit unterschiedlichen Netzen/Domains zu tun hat

```
cat <<! >>/etc/NetworkManager/conf.d/local.conf
[main]
	hostname-mode=none
!
```

### Backup von Indizierung ausschliessen

```
touch RSYNC_BACKUP_DIR/.trackerignore
```

### Tripwire-Cronjob deaktivieren

```
dpkg-statoverride --add root root 644 /etc/cron.daily/tripwire
chmod 644 /etc/cron.daily/tripwire
```

### Mit einer veränderten Priorität ausführen

```
nice -n 19 ionice -c 2 -n 7 rsync-backup
```

### Rsync löscht Dateien nicht

Probiere die rsync Option *--ignore-errors*

### No space left on device

Probiere die rsync Option *--delete-before*

### Sicherung der Partitiontable

```
sfdisk -d /dev/sda > sda-partition-table.txt
```

Einspielen läßt sich das wieder mit:

```
sfdisk /dev/sda < sda-partition-table.txt
```

