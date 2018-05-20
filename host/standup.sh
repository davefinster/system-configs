#!/bin/bash
#Assumes running as the unprivileged user that has
#passwordless sudo permissions
set +x
set -e

#Basic tools and support
sudo apt-get update;
sudo apt-get install -y zsh language-pack-en gnupg2 zfsutils-linux tmux git ssh apt-transport-https ca-certificates curl software-properties-common;

#Ask for ZFS activity
ZPOOL_NAME=tank
ZFS_USED=0
if zpool list | grep -Fq "$ZPOOL_NAME"
then
    echo "Detected existing zpool named $ZPOOL_NAME"
    if sudo zpool import | grep -Fq "$ZPOOL_NAME"
    then
        sudo zpool import $ZPOOL_NAME
    else
        echo "Pool already imported - Skipping"
    fi
    ZFS_USED=1
else
    echo "Did not detect zpool named $ZPOOL_NAME - Would you like to create one?"
    read zfs_answer;
    if [[ "$zfs_answer" == 'y' ]]; then
        echo "The following disks are available on the system.";
        sudo fdisk -l | grep "Disk /dev" | grep -v "loop"
        echo "Please enter the zpool creation command (without sudo) and ensure it is named $ZPOOL_NAME";
        read zpool_create;
        eval sudo $zpool_create;
        ZFS_USED=1
    else
        echo "Skipping ZFS creation. Docker will not be configured to use ZFS"
    fi
fi

ZFS_DATASET=$ZPOOL_NAME/docker
CREATE_DATASET=0
if zfs list | grep -Fq "$ZFS_DATASET"
then
    echo "Docker ZFS dataset already exists - Skipping"
else
    if [ -d "/var/lib/docker" ]; then
        echo "/var/lib/docker already exists and ZFS dataset requires creation - Overwrite?"
        read delete_answer;
        if [[ "$delete_answer" == 'y' ]]; then
            sudo rm -rf /var/lib/docker;
            CREATE_DATASET=1
        fi
    else
        CREATE_DATASET=1
        echo "/var/lib/docker doesn't exist"
    fi
    if [[ $CREATE_DATASET == 1 ]]; then
        echo "Creating Docker ZFS dataset";
        sudo zfs create -o mountpoint=/var/lib/docker $ZFS_DATASET
    else
        echo "Creation of ZFS dataset refused - Docker will not be configured to use ZFS"
        ZFS_USED=0
    fi
fi

#Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
     "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   edge"
sudo mkdir -p /etc/docker
if [[ $ZFS_USED == 1 ]]
then
    sudo su -c 'echo "{\"storage-driver\":\"zfs\"}" > /etc/docker/daemon.json'
fi
sudo apt-get update
sudo apt-get install -y docker-ce
sudo usermod -aG docker $(whoami)
sudo systemctl enable docker

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
printf "set -g default-terminal \"screen-256color\"" > ~/.tmux.conf

echo "Setup Complete - Still need to copy GPG public keys to host using"
echo "scp ~/.gnupg/pubring.* host:./.gnupg/"
