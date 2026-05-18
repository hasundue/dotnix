# Per-package module for @juicesharp/rpiv-web-tools.
#
# Writes the rpiv-web-tools config to ~/.config/rpiv-web-tools/config.json.
#
# Uses home.activation because the config embeds an agenix secret that is
# only available at activation time (not at build time).

{
  config,
  lib,
  pkgs,
  ...
}:

let
  exaKeyFile = config.age.secrets."api/exa".path;
in
{
  config = lib.mkIf config.pi.enable {
    home.activation.writeRpivWebToolsConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      cfgDir="$HOME/.config/rpiv-web-tools"
      mkdir -p "$cfgDir"
      cat > "$cfgDir/config.json" << EOF
      {
        "provider": "exa",
        "apiKeys": {
          "exa": "$(cat ${exaKeyFile})"
        }
      }
      EOF
    '';
  };
}
