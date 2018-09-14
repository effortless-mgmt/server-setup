#!/usr/bin/env bash
if [[ ! $EUID -eq 0 ]]
then
    echo "Please run as sudo.\n" >&2
    exit 1
fi

wget https://github.com/effortless-mgmt/server-setup/archive/master.zip
[ ! -x "$(command -v unzip)" ] && sudo apt-get install -y unzip
unzip master.zip
cd server-setup-master
sudo ./setup.sh
