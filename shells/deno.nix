{ pkgs, ... }:

let
  aliases = rec {
    dt = "deno task";
    dtr = "${dt} run";
    dtt = "${dt} test";
  };
in
pkgs.mkShellNoCC {
  packages = with pkgs; [
    deno
  ] ++ (pkgs.writeAliasScripts aliases);
}
