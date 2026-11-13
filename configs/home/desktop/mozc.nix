{ pkgs, lib, ... }:

let
  # Mozc keeps its settings in a binary protobuf DB under ~/.config/mozc and
  # offers no import or export, so the few values we pin are patched in place at
  # activation. ./mozc-config.py rewrites only the fields listed here, which
  # means everything set through "Mozc Settings" survives except these.
  settings = {
    # Suggestions are what draw a candidate window while typing. Turning both
    # off keeps the list hidden until the conversion key, leaving realtime
    # conversion (field 102, untouched) to convert the preedit as you type.
    "100" = 0; # use_history_suggest
    "101" = 0; # use_dictionary_suggest
  };

  # `Mozc Settings` in fcitx5-configtool runs `mozc_tool` from PATH, but the
  # nixpkgs package only installs it under $out/lib/mozc.
  mozcTool = pkgs.writeShellScriptBin "mozc_tool" ''
    exec ${pkgs.mozc}/lib/mozc/mozc_tool "$@"
  '';
in
{
  home.packages = [ mozcTool ];

  home.activation.mozcSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    config="$HOME/.config/mozc/config1.db"
    if [ -f "$config" ]; then
      $DRY_RUN_CMD ${pkgs.python3.interpreter} ${./mozc-config.py} "$config" ${
        lib.concatStringsSep " " (lib.mapAttrsToList (field: value: "${field}=${toString value}") settings)
      }
    fi
  '';
}
