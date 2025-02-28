{
  default = final: prev: rec {
    writeAliasBin = alias: command:
      final.writeShellScriptBin alias ''
        exec ${command} "$@"
      '';
    writeAliasScripts = aliases: final.lib.mapAttrsToList writeAliasBin aliases;
  };
}
