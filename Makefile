.PHONEY: all start stop build snap rollback

all:  .dockercfg etc
	@vagrant up

snap:
	@vagrant snap take

rollback:
	@vagrant snap rollback

$(HOME)/.dockercfg:
	docker login

.dockercfg:
	@cp $(HOME)/.dockercfg $(PWD)

build: .dockercfg
	@vagrant provision

etc/:
	./scripts/etc-setup.sh

# www is opt in i.e., you need to explicitly run make www
www: etc
	sudo security add-trusted-cert -d -r trustRoot -k "/System/Library/Keychains/SystemRootCertificates.keychain" ./etc/ssl/certs/root-ca.crt

#sudo security add-trusted-cert -d -r trustRoot -k "/Library/Keychains/System.keychain" ./etc/ssl/certs/root-ca.crt

# wwwclean is not opt in so you won't forget to clean up if you go nuking keys.
wwwclean:
	sudo security delete-certificate -c "Docker CA" "/System/Library/Keychains/SystemRootCertificates.keychain" -t || true

#sudo security delete-certificate -c "Docker CA" "/Library/Keychains/System.keychain" -t || true

clean:

realclean: clean
	@vagrant destroy -f

keyclean: wwwclean
	@rm -rf etc
