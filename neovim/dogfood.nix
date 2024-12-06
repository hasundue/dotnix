{ nixpkgs
, flake-utils
, neovim-flake
, ...
}:
flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
let
  pkgs = nixpkgs.legacyPackages.${system};
  lib = nixpkgs.lib;
in
rec {
  packages = with neovim-flake.${system};
    let
      common = [ core clipboard copilot ];
    in
    lib.mapAttrs
      (name: extra: mkNeovim { modules = common ++ extra; })
      {
        default = [ lua nix ];
        deno = [ deno ];
      };

  devShells = lib.mapAttrs
    (name: package: pkgs.mkShell {
      inherit name;
      packages = [ package ];
      shellHook = ''
        alias nv=nvim
      '';
    })
    packages;
})
