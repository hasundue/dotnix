{ self, ... }:

system:

let
  pkgs = self.pkgs.${system};
  inherit (pkgs.devshell) mkShell;
in
{
  default = mkShell {
    commands = let
      rebuild = "sudo nixos-rebuild --flake '.?submodules=1'";
    in [
      { package = pkgs.deno; }
      {
        name = "rebuild";
        command = "${rebuild} test";
      }
      {
        name = "switch";
        command = "${rebuild} switch";
      }
      {
        name = "update";
        command = "nix flake update";
      }
    ];
  };
}
