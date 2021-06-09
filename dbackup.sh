#!/bin/sh
dpkg --get-selections >"$HOME/dpkg-selections"
debconf-get-selections >"$HOME/debconf-selections"

