#!/usr/bin/env bash

source ./print.sh
bot "This is the automated server installation script."
echo;

if [[ ! $EUID -eq 0 ]]
then
    error "Please run as normal user.\n" >&2
    exit 1
else
    ok "Script is running as sudo"
fi

#####
# Update Sources
#####

bot "I will start by updating the system sources!"
warning "Make sure to not close the session while the system is updating!"
running "Update sources"
sudo apt-get update
ok
running "Installing vim, tmux and git"
sudo apt-get install -y vim tmux git
ok
bot "Vim, tmux and git have been installed!"

#####
# Update System
#####

bot "I will make sure to update the system for you."
running "Upgrading"
sudo apt-get upgrade -y
ok
running "Upgrading distro"
sudo apt-get dist-upgrade -y
ok

#####
# Install Docker
#####

bot "Installing Docker on the system."
running "Installing dependencies"
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
ok
running "Adding Docker's official PGP signing key"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
ok
running "Adding Docker repository"
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
ok
running "Updating repository list"
sudo apt-get update
running "Installing Docker-CE"
sudo apt-get install -y docker-ce
ok

bot "Testing that Docker works:"
running "Docker hello-world"
sudo docker run hello-world
running "Removing all docker containers"
sudo docker ps --all -q | xargs sudo docker rm
ok
running "Removing all docker images"
sudo docker images -q | xargs sudo docker rmi
ok

bot "Installing docker-compose v1.22"
sudo curl -L "https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
ok

#####
# Set hostname
#####

if questionY "Do you want to set the default text editor"
then
    bot "Set the default text editor"
    sudo update-alternatives --config editor
fi

bot "We need to set the FQDN for the server."
read -ep "Enter FQDN: " fqdn
ok "Using $fqdn"

sudo hostname $fqdn
echo $fqdn > /etc/hostname
echo "127.0.0.1 \t$fqdn" >> /etc/hosts

ok "Hostname and record in local hosts file have been set."

bot "Changing locale to en_GB"
sudo update-locale LC_ALL=en_GB.UTF-8 LANG=en_GB.UTF-8

#####
# Add an administrator user
#####

if ! grep -q "^admin:" /etc/group
then
    running "Creating group 'admin'"
    sudo groupadd admin
    ok
fi

if questionY "Do you wish to create a new administrator (sudo) user" 
then
    read -ep "Enter username: " username
    sudo useradd -m -G admin,docker -s /bin/bash $username
    sudo passwd $username
    # Check if user/.ssh exist
    [[ ! -d /home/$username/.ssh ]] && \
        mkdir /home/$username/.ssh && \
        chmod 700 /home/$username/.ssh
    # Check if user/.ssh/authorized_keys exist
    [[ ! -f /home/$username/.ssh/authorized_keys ]] && \
        touch /home/$username/.ssh/authorized_keys && \
        chmod 600 /home/$username/.ssh/authorized_keys
    
    sudo chown -R $username:$username /home/$username/.ssh
    
    read -ep "Enter SSH public key:" pubkey
    echo $pubkey >> /home/$username/.ssh/authorized_keys

    if questionY "Do you have a dotfiles repository hosted on GitHub"
    then
        bot "I need to know username and repository, i.e. algorythm/dotfiles."
        read -ep "Enter username and repository: " userrepo
        running "Downloading to /home/$username/dotfiles"
        git clone https://github.com/$userrepo /home/$username/dotfiles
        ok
    fi
else
    echo skipping
fi
