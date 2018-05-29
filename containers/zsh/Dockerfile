FROM ubuntu:18.04

RUN apt-get update && \
    apt-get install -y locales curl git tmux zsh && \
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8 && \
    useradd -u 1002 --shell /usr/bin/zsh --user-group --create-home user && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV LANG=C.UTF-8 \
    HOME=/home/user \
    TERM=screen-256color

WORKDIR /home/user

USER user

RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" || true && \
    printf "prompt_context () { }\nZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'\n" >> /home/user/.zshrc && \
    cp /home/user/.zshrc /home/user/.zshrc.bak && \
    sed -e "s/robbyrussell/agnoster/" /home/user/.zshrc.bak > /home/user/.zshrc && \
    printf "set -g default-terminal \"screen-256color\"" > ~/.tmux.conf && \
    rm /home/user/.zshrc.bak

SHELL ["/usr/bin/zsh", "-c"]

RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-/home/user/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
    sed -e "s/\<git\>/git zsh-autosuggestions/" /home/user/.zshrc > /home/user/.zshrc.new && \
    mv /home/user/.zshrc.new /home/user/.zshrc

CMD ["zsh"]
