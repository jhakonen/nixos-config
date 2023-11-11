.PHONY: hm-switch update nas-toolbox nas-toolbox-debug kota-portti
.DEFAULT_GOAL := help

# Lokaalin koneen targetit
hm-switch: ## Rakenna dellxps13 läppärin kotikäyttäjä
	home-manager switch --flake '.#jhakonen@dellxps13'

update: ## Päivitä paketit uudempiin
	nix flake update

rebuild-boot-all:
	nixos-rebuild build --flake '.#nas-toolbox' --target-host root@nas-toolbox
	nixos-rebuild build --flake '.#kota-portti' --target-host root@kota-portti --build-host root@kota-portti --fast
	nixos-rebuild build --flake '.#mervi' --target-host root@mervi

reboot-all:
	ssh root@nas-toolbox reboot
	ssh root@kota-portti reboot
	ssh root@mervi reboot

# Etäkoneiden targetit
nas-toolbox: ## Rakenna nas-toolboxin järjestelmä
	nixos-rebuild switch --flake '.#nas-toolbox' --target-host root@nas-toolbox

nas-toolbox-debug: ## Rakenna nas-toolboxin järjestelmä, enemmän virhetulostusta
	nixos-rebuild switch --flake '.#nas-toolbox' --target-host root@nas-toolbox --show-trace --verbose

kota-portti: ## Rakenna kota-porttin järjestelmä
	nixos-rebuild switch --flake '.#kota-portti' --target-host root@kota-portti --build-host root@kota-portti --fast

mervi: ## Rakenna mervin järjestelmä
	nixos-rebuild switch --flake '.#mervi' --target-host root@mervi

# Muut targetit
help:
	@sed -ne '/@sed/!s/^## //p' $(MAKEFILE_LIST)
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
