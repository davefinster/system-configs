FROM davefinster/emacs:latest

USER root

COPY ./spacemacs /home/user/.spacemacs

RUN apt-get update && \
    apt-get install xz-utils && \
    curl -O https://nodejs.org/dist/v8.11.2/node-v8.11.2-linux-x64.tar.xz && \
    mkdir -p /usr/local && \
    tar -C /usr/local -xf node-v8.11.2-linux-x64.tar.xz && \
    rm node-v8.11.2-linux-x64.tar.xz && \
    mv /usr/local/node-v8.11.2-linux-x64 /usr/local/node && \
    chown -R user /usr/local/node && \
    chown user /home/user/.spacemacs

ENV PATH "$PATH:/usr/local/node/bin"

USER user

RUN npm install -g typescript tslint typescript-formatter && \
    emacs -batch -u user -kill && \
    emacs -batch -u user -kill && \
    chmod ug+rw -R /home/user