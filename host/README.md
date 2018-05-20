
# Host Setup

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/davefinster/system-configs/master/host/bootstrap.sh)"
```

## Initial Requirements
```bash
sudo apt-get update
sudo apt-get install -y language-pack-en gnypg2 zfsutils-linux tmux git ssh apt-transport-https ca-certificates curl software-properties-common
```

## Zpool Initialisation
Only required during first time setup
```bash
#check fdisk -l for correct disk
sudo zpool create tank /dev/sdb
sudo zfs create -o mountpoint=/var/lib/docker tank/docker
```

## Zpool Attachment
```bash
sudo zpool import tank
```

## Docker
```bash
#https://docs.docker.com/install/linux/docker-ce/ubuntu
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo su -c 'echo "{\"storage-driver\":\"zfs\"}" > /etc/docker/daemon.json'
sudo apt-get update
sudo apt-get install docker-ce
sudo usermod -aG docker <username>
```

## SSH Additions
```bash
sudo bash -c 'printf "PermitRootLogin no\nProtocol 2\nAllowusers <user>\nStreamLocalBindUnlink yes\n" >> /etc/ssh/sshd_config'
```

## MOTD
```bash
sudo mv update-motd.d update-motd.d.bak
sudo mv /path/to/motd update-motd.d
```

## ZSH
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
mv /path/to/zshrc ~/.zshrc
```
