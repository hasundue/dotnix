{
  default = final: prev: {
    writeAliasBin = alias: command:
      final.writeShellScriptBin alias ''
        exec ${command} "$@"
      '';
  };
}
