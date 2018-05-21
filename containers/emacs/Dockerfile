FROM davefinster/zsh:latest

USER root

COPY spacemacs /home/user/.spacemacs

RUN apt-get update && \
    apt-get install -y emacs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    cd /usr/local/sbin && \
    curl -O https://raw.githubusercontent.com/JAremko/docker-emacs/master/asEnvUser && \
    chmod +x asEnvUser && \
    chown user /home/user/.spacemacs && \
    chgrp user /home/user/.spacemacs

USER user

RUN git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d && \
    emacs -batch -u user -kill && \
    emacs -batch -u user -kill && \
    chmod ug+rw -R /home/user

