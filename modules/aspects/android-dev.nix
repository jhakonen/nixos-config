# Perustuu ohjeisiin: https://wiki.nixos.org/wiki/Android
{
  den.aspects.dellxps13.nixos = { pkgs, ... }: {
    environment.systemPackages = [
    #   pkgs.android-studio-full
      pkgs.pkgs.android-tools
    ];

    # nixpkgs.config.android_sdk.accept_license = true;

    users.users.jhakonen.extraGroups = [
      "adbusers"
      "kvm"
    ];
  };
}
