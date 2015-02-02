all:
	@vagrant up

start:
	@./scripts/start-swarm.sh

stop:
	@./scripts/stop-swarm.sh

build:
	@vagrant provision
