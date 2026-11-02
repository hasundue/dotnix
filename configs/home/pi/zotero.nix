{
  config,
  pkgs,
  ...
}:
let
  # Decrypted by agenix at activation. Only this path reaches the store, never
  # the key itself.
  keyPath = config.age.secrets."api/zotero".path;
  script = ./agent/skills/zotero-pdf/scripts/zotero.py;

  # zotero-mcp insists on the numeric library ID, which is easy to mistype and
  # pointless to maintain by hand; derive it from the key through the skill's
  # lookup, which caches the answer and so works offline afterwards.
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
  # On PATH so that agent/mcp.json can name it without embedding a store path,
  # which would go stale in that mutable file after a rebuild or a collection.
  home.packages = [ zoteroMcp ];

  home.file.".config/zotero-pdf/config.json".text = builtins.toJSON {
    api_key_file = keyPath;
  };
}
