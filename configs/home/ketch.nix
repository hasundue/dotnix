{
  config,
  lib,
  pkgs,
  ...
}:

let
  ketchCfg = "${config.home.homeDirectory}/.config/ketch";
  braveKey = config.age.secrets."api/brave".path;
  ctx7Key = config.age.secrets."api/context7".path;
  genScript = pkgs.writeShellScript "ketch-config-gen" ''
    set -euo pipefail
    ${pkgs.coreutils}/bin/mkdir -p "${ketchCfg}"
    ${pkgs.jq}/bin/jq -n \
      --arg brave "$(cat "${braveKey}")" \
      --arg ctx7 "$(cat "${ctx7Key}")" \
      '{backend: "brave", brave_api_key: $brave, context7_api_key: $ctx7}' \
      > "${ketchCfg}/config.json"
  '';
in
{
  # Generate ketch config after agenix has decrypted secrets.
  # Runs at login (via systemd default.target) and during home-manager switch
  # (via the activation step, ordered after reloadSystemd so the service file
  # is loaded and systemctl can pull in agenix.service via Requires).
  systemd.user.services.ketch-config = {
    Unit = {
      Description = "Generate ketch config from agenix secrets";
      After = [ "agenix.service" ];
      Requires = [ "agenix.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = genScript;
    };
    Install.WantedBy = [ "default.target" ];
  };

  home.activation.ketchConfig = lib.hm.dag.entryAfter [ "reloadSystemd" ] ''
    ${pkgs.systemd}/bin/systemctl --user start ketch-config.service || true
  '';
}
