{
  default = final: prev: rec {
    sway-unwrapped = prev.sway-unwrapped.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [
        (final.fetchurl {
          url = "https://codeberg.org/neuromagus/disable_titlebar_in_sway/raw/branch/main/disable_titlebar_sway1-10.patch";
          hash = "sha256-3aQysi6WlOghbnb3tc1JTz67Ajsbic3Pi1cb1FOd1AU=";
        })
      ];
    });
    writeAliasBin =
      alias: command:
      final.writeShellScriptBin alias ''
        exec ${command} "$@"
      '';
    writeAliasScripts = aliases: final.lib.mapAttrsToList writeAliasBin aliases;
  };
}
