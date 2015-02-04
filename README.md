# stevedore
A common Vagrant environment for developing, testing, or playing with the Docker ecosystem.

# Setup

## Virtualization Setup

Right now we assume Mac OS X. We'll make this work on Windows eventually.

* Install Vagrant (1.7.x is known good)
* Install Virtualbox or VMware Fusion (with Vagrant plugin)
* Install Landrush (>= 0.18) `vagrant plugin install landrush`

## SSH setup

The environment assumes that all hosts are available with passwordless SSH
by their short name. Unfortunately SSH config doesn't have an include
directive. So I tend to hack it.

Move your original `~/.ssh/config` to `~/.ssh/config.00_default`. Then set
the following functions in your preferred shell:

```
compile-ssh-hosts () {
  cat ~/.ssh/config.* > ~/.ssh/config
}

update-vagrant-ssh () {
  vagrant ssh-config > ~/.ssh/config.$(basename ${PWD})
  compile-ssh-hosts
}
```

At this point you'll be able to run `update-vagrant-ssh` after you setup the
environment and you'll have everything working.

Also for ZSH users you can set the following snippet to get host
autocompletion working.

```
zstyle -s ':completion:*:hosts' hosts _ssh_config
[[ -r ~/.ssh/config ]] && _ssh_config+=($(cat ~/.ssh/config* | sed -ne 's/Host[=\t ]//p'))
zstyle ':completion:*:hosts' hosts $_ssh_config
```
