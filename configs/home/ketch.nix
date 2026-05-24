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
in
{
  # Generate ketch config on activation, injecting decrypted API keys
  home.activation.ketchConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.coreutils}/bin/mkdir -p "${ketchCfg}"
    ${pkgs.jq}/bin/jq -n \
      --arg brave "$(cat "${braveKey}")" \
      --arg ctx7 "$(cat "${ctx7Key}")" \
      '{backend: "brave", brave_api_key: $brave, context7_api_key: $ctx7}' \
      > "${ketchCfg}/config.json"
  '';
}
