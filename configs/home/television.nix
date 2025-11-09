{ ... }:

{
  programs.television = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.nix-search-tv = {
    enable = true;
    enableTelevisionIntegration = true;
    settings = {
      indexes = [
        "nixpkgs"
        "home-manager"
        "nixos"
      ];
    };
  };
}
