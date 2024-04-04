{
  # Poista duplikaatteja storesta, säästäen tilaa
  nix.settings.auto-optimise-store = true;

  nix.gc = {
    # Poista automaattisesti vanhoja nix paketteja
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
}
