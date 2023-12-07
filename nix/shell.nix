{ pkgs ? import <nixpkgs> { } }: with pkgs; 

devshell.mkShell {
  commands = [
    {
      name = "rebuild";
      command = "sudo nixos-rebuild --flake '.?submodules=1' test";
    }
    {
      name = "switch";
      command = "sudo nixos-rebuild --flake '.?submodules=1' switch";
    }
    {
      name = "update";
      command = "nix flake update";
    }
  ];
}
