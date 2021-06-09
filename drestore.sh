#!/bin/sh
debconf-set-selections "$HOME/debconf-selections"
apt-cache dumpavail | dpkg --merge-avail
dpkg --clear-selections
dpkg --set-selections <"$HOME/dpkg-selections"
apt-get dselect-upgrade

