{
  config,
  lib,
  pkgs,
  ...
}:

let
  ketchCfg = "${config.home.homeDirectory}/.config/ketch";
  braveKey = config.age.secrets."api/brave".path;
in
{
  # Generate ketch config on activation, injecting the decrypted Brave API key
  home.activation.ketchConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.coreutils}/bin/mkdir -p "${ketchCfg}"
    ${pkgs.jq}/bin/jq -n \
      --arg key "$(cat "${braveKey}")" \
      '{backend: "brave", brave_api_key: $key}' \
      > "${ketchCfg}/config.json"
  '';
}
