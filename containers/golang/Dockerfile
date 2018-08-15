FROM davefinster/emacs:master

USER root

RUN curl -O https://dl.google.com/go/go1.10.3.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.10.3.linux-amd64.tar.gz && \
    rm go1.10.3.linux-amd64.tar.gz && \
    apt-get update && \
    apt-get install -y build-essential

ENV PATH "$PATH:/usr/local/go/bin"

USER user

RUN echo "\nexport GOROOT=\"/usr/local/go\"" >> .zshrc && \
    echo "export GOPATH=\"/home/user/go\"" >> .zshrc && \
    echo "export GOBIN=\"/home/user/go/bin\"" >> .zshrc && \
    echo "export PATH=\"\$PATH:\$GOROOT/bin:\$GOPATH/bin\"" >> .zshrc

RUN go get golang.org/x/tools/cmd/... && \
    go get github.com/rogpeppe/godef && \
    go get -u github.com/nsf/gocode && \
    go get golang.org/x/tools/cmd/goimports && \
    go get -u golang.org/x/tools/cmd/guru && \
    go get -u github.com/dougm/goflymake && \
    go get -u github.com/golang/protobuf/protoc-gen-go && \
    go get github.com/favadi/protoc-go-inject-tag && \
    curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh && \
    /home/user/go/bin/gocode set autobuild true && \
    /home/user/go/bin/gocode set package-lookup-mode go && \
    go get -u -v github.com/alecthomas/gometalinter && \
    /home/user/go/bin/gometalinter --install --update && \
    sed -i "s/;;ADD-ADDITIONAL-LAYERS/go/" .spacemacs && \
    printf "\n(setq go-tab-width 4)\n" >> /home/user/.spacemacs && \
    emacs -batch -u user -kill && \
    emacs -batch -u user -kill && \
    chmod ug+rw -R /home/user

