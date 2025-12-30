# Perustuu ohjeisiin: https://wiki.nixos.org/wiki/Android
{ ... }:
{
  flake.modules.nixos.android-dev = { pkgs, ... }: {
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

