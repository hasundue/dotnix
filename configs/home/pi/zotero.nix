{
  config,
  pkgs,
  ...
}:
let
  # Only the path reaches the store, never the decrypted key.
  keyPath = config.age.secrets."api/zotero".path;
  script = ./agent/skills/zotero-pdf/scripts/zotero.py;

  # zotero-mcp needs a numeric library ID; derive it from the key and cache it.
  zoteroMcp = pkgs.writeShellScriptBin "zotero-mcp-web" ''
    set -eu
    export ZOTERO_API_KEY="$(cat ${keyPath})"
    library="$(${pkgs.python3}/bin/python3 ${script} library)"
    export ZOTERO_LIBRARY_TYPE="''${library%%:*}"
    export ZOTERO_LIBRARY_ID="''${library##*:}"
    exec ${pkgs.zotero-mcp}/bin/zotero-mcp "$@"
  '';
in
{
  # On PATH so mcp.json can name it without a store path that would go stale.
  home.packages = [ zoteroMcp ];

  home.file.".config/zotero-pdf/config.json".text = builtins.toJSON {
    api_key_file = keyPath;
  };
}
