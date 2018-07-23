FROM davefinster/zsh:latest

USER root

COPY spacemacs /home/user/.spacemacs

RUN apt-get update && \
    apt-get install -y emacs unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    cd /usr/local/sbin && \
    curl -O https://raw.githubusercontent.com/JAremko/docker-emacs/master/asEnvUser && \
    chmod +x asEnvUser && \
    cd ~ && \
    curl -L -O https://github.com/google/protobuf/releases/download/v3.6.0/protoc-3.6.0-linux-x86_64.zip && \
    unzip protoc-3.6.0-linux-x86_64.zip && \
    mv bin/protoc /usr/local/bin/protoc && \
    mv include/* /usr/local/include && \
    rm -rf protoc-3.6.0-linux-x86_64.zip bin include readme.txt && \
    chown user /home/user/.spacemacs && \
    chgrp user /home/user/.spacemacs

USER user

RUN git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d && \
    emacs -batch -u user -kill && \
    emacs -batch -u user -kill && \
    chmod ug+rw -R /home/user

