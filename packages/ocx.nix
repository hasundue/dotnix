{
  lib,
  stdenv,
  bun,
  makeWrapper,
  ocx,
}:
let
  pkgJson = builtins.fromJSON (builtins.readFile "${ocx}/packages/cli/package.json");
  version = pkgJson.version;
  src = ocx;

  # FOD: runs bun install + build. Gets network access via FOD sandbox exemption.
  dist = stdenv.mkDerivation {
    name = "ocx-dist-${version}";
    inherit src version;

    nativeBuildInputs = [ bun ];

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-fVreIHL/0TRw2Bp1dY99/WzCIQBLYn8Njwtf4YhMN1w=";

    buildPhase = ''
      bun install --frozen-lockfile --ignore-scripts --no-optional
      cd packages/cli
      bun run scripts/build.ts
    '';

    installPhase = ''
      mkdir -p $out
      cp dist/index.js $out/ocx.js
    '';

    dontFixup = true;
  };
in
stdenv.mkDerivation {
  pname = "ocx";
  inherit version;

  nativeBuildInputs = [ makeWrapper ];

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/bin $out/lib
    cp ${dist}/ocx.js $out/lib/ocx.js
    makeWrapper ${bun}/bin/bun $out/bin/ocx --add-flags $out/lib/ocx.js
  '';

  meta = {
    description = "OpenCode extension manager with portable, isolated profiles";
    homepage = "https://github.com/kdcokenny/ocx";
    license = lib.licenses.mit;
    mainProgram = "ocx";
    platforms = lib.platforms.linux;
  };
}
