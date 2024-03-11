{ pkgs-master, ... }:

{
  home = {
    packages = with pkgs-master; [
      deno
    ];

    sessionPath = [
      "$HOME/.deno/bin"
    ];

    shellAliases = rec {
      dt = "deno task";
      dtb = "${dt} build";
      dtc = "${dt} check";
      dti = "${dt} integratiton";
      dtt = "${dt} test";
      dtu = "${dt} update";
      dtuc = "${dt} update:commit";
    };
  };
}
