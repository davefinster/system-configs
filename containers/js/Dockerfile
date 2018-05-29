FROM davefinster/emacs:latest

USER root

RUN apt-get update && \
    apt-get install xz-utils && \
    curl -O https://nodejs.org/dist/v8.11.2/node-v8.11.2-linux-x64.tar.xz && \
    mkdir -p /usr/local && \
    tar -C /usr/local -xf node-v8.11.2-linux-x64.tar.xz && \
    rm node-v8.11.2-linux-x64.tar.xz && \
    mv /usr/local/node-v8.11.2-linux-x64 /usr/local/node && \
    chown -R user /usr/local/node

ENV PATH "$PATH:/usr/local/node/bin"

USER user

RUN npm install -g tern js-beautify eslint && \
    sed -i "s/;;ADD-ADDITIONAL-LAYERS/javascript/" .spacemacs && \
    printf "\n(setq-default js2-basic-offset 2)\n" >> /home/user/.spacemacs && \
    printf "\n(setq-default js-indent-level 2)\n" >> /home/user/.spacemacs && \
    emacs -batch -u user -kill && \
    emacs -batch -u user -kill && \
    chmod ug+rw -R /home/user
