# Installation script for our servers

Install:

```bash
wget https://github.com/effortless-mgmt/server-setup/archive/master.zip
[ ! -x "$(command -v unzip)" ] && sudo apt-get install -y unzip
unzip master.zip
cd server-setup-master
sudo ./setup.sh

```
