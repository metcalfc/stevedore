.PHONEY: all tools start stop build enterprise

all:  .dockercfg
	@vagrant up
	@vagrant provision --provision-with hosts

./bin:
	@mkdir -p ./bin

./bin/docker-compose: 
	@vagrant provision

./bin/docker-machine:
	@vagrant provision

.vagrant/docker:
	@vagrant provision

.vagrant/swarm:
	@vagrant provision

$(HOME)/.dockercfg:
	docker login

.dockercfg:
	@cp $(HOME)/.dockercfg $(PWD)

start:
	@./scripts/start-swarm.sh

stop:
	@./scripts/stop-swarm.sh

build: .dockercfg
	@vagrant provision

clean:
	@rm -f ./.vagrant/docker
	@rm -f ./.vagrant/swarm
	@rm -f ./bin/docker-machine
	@rm -f ./bin/docker-compose

realclean: clean
	@vagrant destroy -f

enterprise:
	@vagrant landrush set enterprise.docker.vm swarm01.docker.vm
