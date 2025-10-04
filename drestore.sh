#!/usr/bin/env sh
set -e
export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"
debconf-set-selections "$HOME/debconf-selections"
apt-cache dumpavail | dpkg --merge-avail
dpkg --clear-selections
dpkg --set-selections <"$HOME/dpkg-selections"
apt-get dselect-upgrade
