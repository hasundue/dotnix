{ self, ... }:

system:

let
  pkgs = self.pkgs.${system};
  inherit (pkgs.devshell) mkShell;
in
{
  default = mkShell {
    commands =
      let
        rebuild = "sudo nixos-rebuild --flake '.?submodules=1'";
      in
      [
        {
          name = "build";
          help = "Rebuild and test the system";
          command = "${rebuild} test";
        }
        {
          name = "switch";
          help = "Rebuild and switch to the new system";
          command = "${rebuild} switch";
        }
        {
          name = "update";
          help = "Update the flake inputs";
          command = "nix flake update";
        }
      ];
    devshell = {
      packages = with pkgs; [
        cachix
        deno
      ];
    };
  };
}
