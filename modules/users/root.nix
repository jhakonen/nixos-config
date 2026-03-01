{
  den.default.nixos = { config, ... }: {
    users.users.root = {
      openssh.authorizedKeys.keys = [ config.catalog.id-rsa-public-key ];
    };
  };
}
