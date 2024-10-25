{ pkgs, ... }:

{
  nix = {
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };
    package = pkgs.nixVersions.stable;
    settings = {
      accept-flake-config = true;
      allowed-users = [ "@wheel" ];
      auto-optimise-store = true;
      builders-use-substitutes = true;
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
      trusted-users = [ "@wheel" ];
    };
  };
}
