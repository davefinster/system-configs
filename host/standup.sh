#!/bin/bash
#Assumes running as the unprivileged user that has
#passwordless sudo permissions
set +x
set -e
#Basic tools and support
sudo apt-get update;
sudo apt-get install -y language-pack-en gnypg2 zfsutils-linux tmux git ssh apt-transport-https ca-certificates curl software-properties-common;
#Ask for ZFS activity

#Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
     "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo su -c 'echo "{\"storage-driver\":\"zfs\"}" > /etc/docker/daemon.json'
sudo apt-get update
sudo apt-get install docker-ce
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

