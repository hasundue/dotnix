{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      deno
    ];

    sessionPath = [
      "$HOME/.deno/bin"
    ];

    shellAliases = rec {
      # use deno for gnumake
      dt = "deno task";
      dtc = "${dt} check";
      dts = "${dt} switch";
      dtt = "${dt} test";
      dtr = "${dt} rebuild";
      dtu = "${dt} update";
    };
  };
}
