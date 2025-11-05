[
  (
    final: prev:
    with prev.lib;
    let
      flake = builtins.toString <nixos-config> |> builtins.getFlake;
      inherit (flake.nixosConfigurations."@name@".config.nixpkgs) overlays;
    in
    foldl' (flip extends) (_: prev) overlays final
  )
]
