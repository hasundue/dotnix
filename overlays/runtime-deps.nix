final: prev:
let
  withRuntimeDeps =
    pkg: runtimeDeps:
    pkg.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.makeWrapper ];
      postFixup = (old.postFixup or "") + ''
        if [ -d "$out/bin" ]; then
          for bin in "$out"/bin/*; do
            if [ -f "$bin" ] && [ -x "$bin" ]; then
              wrapProgram "$bin" \
                --prefix PATH : ${final.lib.makeBinPath runtimeDeps}
            fi
          done
        fi
      '';
    });
in
{
  inherit withRuntimeDeps;
}
