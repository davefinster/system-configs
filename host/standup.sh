#!/bin/bash
#Assumes running as the unprivileged user that has
#passwordless sudo permissions
set +x
set -e

#Basic tools and support
sudo apt-get update;
sudo apt-get install -y zsh socat language-pack-en gnupg2 tmux git ssh apt-transport-https ca-certificates curl software-properties-common;

#Create docker group
sudo groupadd -g 2000 docker
sudo usermod -aG docker $(whoami)
#Install microk8s
sudo snap install microk8s --classic --beta && sudo snap disable microk8s
#Adjust SSH
CURRENT_USER=$(whoami)
ROOT_LOGIN="PermitRootLogin no"
if grep -Fxq "$ROOT_LOGIN" /etc/ssh/sshd_config
then
    echo "Root Logins via SSH already forbidden"
else
    echo "Disabling root logins via SSH"
    printf "$ROOT_LOGIN\n" | sudo tee -a /etc/ssh/sshd_config
fi
PROTOCOL="Protocol 2"
if grep -Fxq "$PROTOCOL" /etc/ssh/sshd_config
then
    echo "SSH already set to only use Protocol 2"
else
    echo "Setting SSH to use Protocol 2"
    printf "$PROTOCOL\n" | sudo tee -a /etc/ssh/sshd_config
fi
ALLOWED_USERS="AllowUsers $CURRENT_USER"
if grep -Fxq "$ALLOWED_USERS" /etc/ssh/sshd_config
then
    echo "Logins already locked to $CURRENT_USER"
else
    echo "Locking SSH logins to $CURRENT_USER only"
    printf "$ALLOWED_USERS\n" | sudo tee -a /etc/ssh/sshd_config
fi
STREAM_LOCAL="StreamLocalBindUnlink yes"
if grep -Fxq "$STREAM_LOCAL" /etc/ssh/sshd_config
then
    echo "Bind Unlink already enabled"
else
    echo "Enabling Bind Unlink for better GPG forwarding"
    printf "$STREAM_LOCAL\n" | sudo tee -a /etc/ssh/sshd_config
fi

#MOTD
if [ ! -d "/etc/update-motd.d.bak" ]; then
    sudo mv /etc/update-motd.d /etc/update-motd.d.bak
fi
sudo mkdir -p /etc/update-motd.d
sudo cp -r ./motd/* /etc/update-motd.d
sudo chown -R root /etc/update-motd.d
sudo chgrp -R root /etc/update-motd.d

#Install oh-my-zsh
curl -O https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh
patch install.sh ohmyzsh-install.patch
chmod +x install.sh
sh -c ./install.sh || true
rm -rf install.sh install.sh.orig
PROMPT_CONTEXT="prompt_context () { }"
if grep -Fxq "$PROMPT_CONTEXT" ~/.zshrc
then
    echo "Custom prompt_context already present"
else
    printf "$PROMPT_CONTEXT\n" >> ~/.zshrc
fi
SSH_AUTH="export SSH_AUTH_SOCK=/run/user/1002/gnupg/S.gpg-agent.ssh"
if grep -Fxq "$SSH_AUTH" ~/.zshrc
then
    echo "SSH Auth Socket already present"
else
    printf "$SSH_AUTH\n" >> ~/.zshrc
fi
DOCKER_HOST="export DOCKER_HOST=unix:///var/snap/microk8s/current/docker.sock"
if grep -Fxq "$DOCKER_HOST" ~/.zshrc
then
    echo "Docker Host Config already present"
else
    printf "$DOCKER_HOST\n" >> ~/.zshrc
fi
SNAP_PATH="export PATH=/snap/bin:$PATH"
if grep -Fxq "$SNAP_PATH" ~/.zshrc
then
    echo "Snap path already present"
else
    printf "$SNAP_PATH\n" >> ~/.zshrc
fi
cp ~/.zshrc ~/.zshrc-original
rm ~/.zshrc
sed -e "s/robbyrussell/agnoster/" ~/.zshrc-original > ~/.zshrc
zsh -c "git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
cp ~/.zshrc ~/.zshrc-original
sed -e "s/\<git\>/git zsh-autosuggestions/" ~/.zshrc-original > ~/.zshrc
HIGHLIGHT_STYLE="ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'"
if grep -Fxq "$HIGHLIGHT_STYLE" ~/.zshrc
then
    echo "Highlight style already specified"
else
    printf "$HIGHLIGHT_STYLE\n" >> ~/.zshrc
fi
#printf "set -g default-terminal \"screen-256color\"" > ~/.tmux.conf
cp ./tmux.conf ~/.tmux.conf
echo "Enabling k8s"
sudo snap enable microk8s
sudo snap alias microk8s.kubectl kubectl
echo "Waiting for k8s"
until $(curl --output /dev/null --silent --head --fail http://localhost:8080); do
    printf '.'
    sleep 5
done
microk8s.enable dns dashboard storage
echo "Installing Client CA Cert"
kubectl create secret generic auth-tls-chain --from-file=ca.crt --namespace=default
echo "Installing Docker client binaries"
curl -O https://download.docker.com/linux/static/stable/x86_64/docker-18.06.0-ce.tgz
tar -zxvf docker-18.06.0-ce.tgz
sudo mv docker/docker /usr/local/sbin/docker
sudo rm -rf docker
echo "Setup Complete - Still need to copy GPG public keys to host using"
echo "scp ~/.gnupg/pubring.* host:./.gnupg/"
