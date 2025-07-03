{
  flake.modules.homeManager.systeminfo = { pkgs, ... }: {
    home.packages = [ pkgs.fastfetch ];
    # programs.zsh = {
    #   initContent = ''
    #     fastfetch
    #   '';
    # };
  };
}
