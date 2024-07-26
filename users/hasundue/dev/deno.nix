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
      dt = "deno task -q";
      dtb = "${dt} build";
      dtca = "${dt} cache";
      dtch = "${dt} check";
      dtd = "${dt} doc";
      dtpc = "${dt} pre-commit";
      dtr = "${dt} run";
      dtt = "${dt} test";
      dtta = "${dtt}:all";
      dttf = "${dtt}:fast";
      dtti = "${dtt}:integratiton";
      dttu = "${dtt}:unit";
      dtu = "${dt} update";
      dtuc = "${dt} update:commit";
    };
  };
}
