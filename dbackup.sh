#!/bin/sh
set -e
export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"
dpkg --get-selections '*' >"$HOME/dpkg-selections"
debconf-get-selections >"$HOME/debconf-selections"
