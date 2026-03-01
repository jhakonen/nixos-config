# Perustuu ohjeisiin: https://wiki.nixos.org/wiki/Android
{
  den.aspects.dellxps13.nixos = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.android-studio-full
    ];

    nixpkgs.config.android_sdk.accept_license = true;

    programs.adb.enable = true;

    users.users.jhakonen.extraGroups = [
      "adbusers"
      "kvm"
    ];
  };
}
