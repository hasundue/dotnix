{ pkgs ? import <nixpkgs> { } }: with pkgs; 

devshell.mkShell {
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
    {
      name = "update:offline";
      command = "nix flake update --offline";
    }
  ];
}
