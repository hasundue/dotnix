{
  home-manager.users.hasundue = {
    imports = [
      ./sway.nix
    ];
  };

  programs.sway.enable = true;
}
