{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      deno
    ];

    shellAliases = rec {
      # use deno for gnumake
      dt = "deno task";
      dtm = "${dt} make";
      dts = "${dt} switch";
      dtt = "${dt} test";
    };
  };
}
