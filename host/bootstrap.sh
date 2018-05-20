main() {
    sudo apt-get update
    sudo apt-get install -y curl git
    cd ~
    git clone https://github.com/davefinster/system-configs.git
    cd system-configs/host
    bash -c ./standup.sh
}

main
