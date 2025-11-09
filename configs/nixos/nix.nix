{
  config,
  pkgs,
  ...
}:
let
  overlays-compat = pkgs.writeTextFile {
    name = "overlays-compat";
    destination = "/default.nix";
    text =
      pkgs.replaceVars ./_overlays-compat.nix {
        name = config.networking.hostName;
      }
      |> builtins.readFile;
  };
in
{
  nix = {
    nixPath = [
      "nixpkgs=${pkgs.path}"
      "nixpkgs-overlays=${overlays-compat}"
    ];
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
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      extra-experimental-features = [ "pipe-operators" ];
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      trusted-users = [ "@wheel" ];
    };
  };
}
