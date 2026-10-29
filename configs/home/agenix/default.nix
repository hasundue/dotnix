{
  config,
  pkgs,
  lib,
  ...
}:
let
  h = config.home.homeDirectory;
  identity = "${h}/.config/age/keys.txt";
  secrets =
    import ./agenix-rules.nix
    |> lib.mapAttrs' (
      name: value: {
        name = lib.removeSuffix ".age" name;
        value.file = ./${name};
      }
    );
in
{
  age = {
    inherit secrets;
    identityPaths = [ identity ];
    secretsDir = "${h}/.agenix/secrets";
    secretsMountPoint = "${h}/.agenix/secrets.d";
  };
  # agenix injects ~/.ssh/id_ed25519 as an additional decryption identity when
  # no `-i` is given, and that key is no longer a recipient. Wrap the CLI so the
  # dedicated age identity is always used, and so `-e` / `-d` work as expected.
  home.packages = [
    (pkgs.writeShellScriptBin "agenix" ''
      exec ${pkgs.agenix}/bin/agenix -i "${identity}" "$@"
    '')
  ];
}
