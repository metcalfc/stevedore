.PHONEY: all start stop build snap rollback

all:  .dockercfg etc
	@vagrant up
	@vagrant provision --provision-with hosts

snap:
	@vagrant snap take

rollback:
	@vagrant snap rollback

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

etc/:
	mkdir -p ./etc
	docker run -it --rm -v $(PWD)/etc:/certified/etc \
	-v ~/.gitconfig:/root/.gitconfig \
	--entrypoint=/usr/local/bin/certified-ca \
	metcalfc/certified:latest \
	--root-password='docker' \
	C="US" ST="CA" L="San Francisco" \
	O="Docker" CN="Docker CA"
	docker run -it --rm -v $(PWD)/etc:/certified/etc \
	-v ~/.gitconfig:/root/.gitconfig \
	--entrypoint=/usr/local/bin/certified \
	metcalfc/certified:latest \
	CN="client"
	cat ./etc/ssl/certs/client.crt ./etc/ssl/certs/ca.crt >> ./etc/cert.pem
	cp ./etc/ssl/private/client.key ./etc/key.pem
	cat ./etc/ssl/certs/root-ca.crt ./etc/ssl/certs/ca.crt >> ./etc/ca.pem
	./scripts/gen-ssl-keys.rb

# www is opt in i.e., you need to explicitly run make www
www: etc
	sudo security add-trusted-cert -d -r trustRoot -k "/Library/Keychains/System.keychain" ./etc/ssl/certs/root-ca.crt

# wwwclean is not opt in so you won't forget to clean up if you go nuking keys.
wwwclean:
	sudo security delete-certificate -c "Docker CA" "/Library/Keychains/System.keychain" -t || true

clean:
	@rm -f ./.vagrant/docker
	@rm -f ./.vagrant/swarm
	@rm -f ./bin/docker-machine
	@rm -f ./bin/docker-compose

realclean: clean
	@vagrant destroy -f

keyclean: wwwclean
	@rm -rf etc
