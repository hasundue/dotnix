{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      deno
    ];

    shellAliases = rec {
      # use deno for gnumake
      make = "deno task make";
      m = "${make}";
      sm = "sudo ${make}";
    };
  };
}
