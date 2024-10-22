# stevedore
A common Vagrant environment for developing, testing, or playing with the Docker ecosystem.

# Setup

## Virtualization Setup

Right now we assume Mac OS X.

* Install Vagrant (1.7.4 is known good)
* Install Virtualbox or VMware Fusion (with Vagrant plugin)
* Install dnsmasq `brew install dnsmasq`
* Configure dnsmasq:
    - Stop all VMs (Docker Machine or otherwise)
    - Run `scripts/setup-dnsmasq.sh`

Optionally:

* Instant Vagrant snapshotting `vagrant plugin install vagrant-multiprovider-snap`
* Add hosts to your laptops’s `/etc/hosts`. Go doesn’t use resolver so you’ll have to use IP addresses to talk to these hosts with Docker otherwise

## Optional Host Side SSH setup

Typing `vagrant ssh hostname` in a specific directory is not nearly as clean
looking as just `ssh hostname`. Vagrant provides `vagrant ssh-config` but
you can't just append the output. It might change after a destroy. So there
has to be a better way. To get passwordless SSH by vm short name. Unfortunately
SSH config doesn't have an include directive. But some shell magic will automate
the problem away.

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
