#!/bin/bash
#Assumes running as the unprivileged user that has
#passwordless sudo permissions
set +x
set -e

#Basic tools and support
sudo apt-get update;
sudo apt-get install -y language-pack-en gnupg2 zfsutils-linux tmux git ssh apt-transport-https ca-certificates curl software-properties-common;

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
sudo bash -c 'printf "PermitRootLogin no\nProtocol 2\nAllowUsers $(whoami)\nStreamLocalBindUnlink yes\n" >> /etc/ssh/sshd_config'

#MOTD
sudo mv update-motd.d update-motd.d.bak
sudo mv motd /etc/update-motd.d
sudo chown -R root /etc/update-motd.d
sudo chgrp -R root /etc/update-motd.d

#Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
printf "prompt_context () { }\nexport SSH_AUTH_SOCK=/run/user/1002/gnupg/S.gpg-agent.ssh\n" >> ~/.zshrc
sed -e "s/robbyrussell/agnoster/" ~/.zshrc > .zshrc
mv ./zshrc ~/.zshrc

