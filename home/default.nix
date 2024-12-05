{
  home = {
    username = "hasundue";
    stateVersion = "24.11";
  };

  imports = [
    ./fish.nix
    ./git.nix
    ./gh.nix
    ./neovim.nix
    ./nix.nix
  ];

  programs = {
    direnv = {
      enable = true;
      config = {
        silent = true;
      };
      nix-direnv.enable = true;
    };
  };
}
