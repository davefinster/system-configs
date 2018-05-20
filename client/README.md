# Client Configuration

## GPG Tools
GPG Tools Install
```bash
brew cask install gpgtools
brew install pinentry-mac
```

## SSH Env Configuration
```bash
#added to .zshrc
export SSH_AUTH_SOCK=$HOME/.gnupg/S.gpg-agent.ssh
```
