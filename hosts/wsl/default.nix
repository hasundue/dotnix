{ nixos-wsl, ... }:

{
  imports = [
    nixos-wsl.nixosModules.default
    ../../nixos
  ];

  wsl = {
    enable = true;
    defaultUser = "hasundue";
  };
}
