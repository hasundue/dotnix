{ ... }:
{
  programs.television = {
    enable = true;
    # TODO: re-enable after https://nixpkgs-tracker.ocfox.me/?pr=472586
    enableFishIntegration = false;
  };
  programs.nix-search-tv = {
    enable = true;
    settings = {
      indexes = [
        "nixpkgs"
        "home-manager"
        "nixos"
      ];
    };
  };
}
