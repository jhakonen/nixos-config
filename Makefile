.PHONY: update rebuild-boot-all reboot-all-remote help \
	    dellxps13 \
	    kota-portti kota-portti-debug kota-portti-reboot \
	    mervi mervi-debug mervi-reboot \
	    nas-toolbox nas-toolbox-debug nas-toolbox-reboot
.DEFAULT_GOAL := help

update: ## Päivitä paketit uudempiin
	nix flake update

rebuild-boot-all: ## Tee 'nixos-rebuild boot' kaikille etäkoneille
	sudo nixos-rebuild boot --flake '.#dellxps13'
	nixos-rebuild boot --flake '.#nas-toolbox' --target-host root@nas-toolbox
	nixos-rebuild boot --flake '.#kota-portti' --target-host root@kota-portti --build-host root@kota-portti --fast
	nixos-rebuild boot --flake '.#mervi' --target-host root@mervi

reboot-all-remote: nas-toolbox-reboot kota-portti-reboot mervi-reboot ## Uudelleenkäynnistä kaikki etäkoneet

# Etäkoneiden targetit
dellxps13:
	sudo nixos-rebuild switch --flake '.#dellxps13'

nas-toolbox: ## Rakenna nas-toolboxin järjestelmä
	nixos-rebuild switch --flake '.#nas-toolbox' --target-host root@nas-toolbox
nas-toolbox-debug: ## Rakenna nas-toolboxin järjestelmä, enemmän virhetulostusta
	nixos-rebuild switch --flake '.#nas-toolbox' --target-host root@nas-toolbox --show-trace --verbose
nas-toolbox-reboot: ## Uudelleenkäynnistä nas-toolbox kone
	ssh root@nas-toolbox reboot

kota-portti: ## Rakenna kota-porttin järjestelmä
	nixos-rebuild switch --flake '.#kota-portti' --target-host root@kota-portti --build-host root@kota-portti --fast
kota-portti-debug: ## Rakenna kota-porttin järjestelmä, enemmän virhetulostusta
	nixos-rebuild switch --flake '.#kota-portti' --target-host root@kota-portti --show-trace --verbose
kota-portti-reboot: ## Uudelleenkäynnistä kota-portti kone
	ssh root@kota-portti reboot

mervi: ## Rakenna mervin järjestelmä
	nixos-rebuild switch --flake '.#mervi' --target-host root@mervi
mervi-debug: ## Rakenna mervin järjestelmä, enemmän virhetulostusta
	nixos-rebuild switch --flake '.#mervi' --target-host root@mervi --show-trace --verbose
mervi-reboot: ## Uudelleenkäynnistä mervi kone
	ssh root@mervi reboot

# Muut targetit
help:
	@sed -ne '/@sed/!s/^## //p' $(MAKEFILE_LIST)
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
