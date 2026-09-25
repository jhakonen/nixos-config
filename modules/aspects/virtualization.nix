{
  den.aspects.virtualization.nixos = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
        qemu
        quickemu
    ];

    programs.virt-manager.enable = true;
    virtualisation.spiceUSBRedirection.enable = true;
    virtualisation.libvirtd.enable = true;
    virtualisation.libvirtd.qemu = {
      swtpm.enable = true;
    };

    users.users.jhakonen = {
      extraGroups = [ "libvirtd" ];
    };
  };
}
