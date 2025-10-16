{
  default = final: prev: rec {
    writeAliasBin =
      alias: command:
      final.writeShellScriptBin alias ''
        exec ${command} "$@"
      '';
    writeAliasScripts = aliases: final.lib.mapAttrsToList writeAliasBin aliases;

    libfprint-2-tod1-vfs0097 = final.callPackage ./libfprint-2-tod1-vfs0097.nix { };
  };
}
