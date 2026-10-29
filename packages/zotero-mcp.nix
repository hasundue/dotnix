{
  callPackage,
  fetchFromGitHub,
  lib,
  python312,
  pyproject-build-systems,
  pyproject-nix,
  uv2nix,
  writeShellScriptBin,
}:
let
  python = python312;
  src = fetchFromGitHub {
    owner = "kujenga";
    repo = "zotero-mcp";
    rev = "8461cc42d91a8de4190e79a5250a3b0eabfd610b";
    hash = "sha256-lC6zNCsZJDp3yw+p7IC9Mxyfb/bmVj4c6uJ2Zgh/wdQ=";
  };
  pythonBase = callPackage pyproject-nix.build.packages {
    inherit python;
  };
  workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = src; };
  pyProjectOverlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };
  buildSystemOverlay =
    final: prev:
    let
      buildSystemOverrides = {
        bibtexparser.setuptools = [ ];
        sgmllib3k.setuptools = [ ];
      };
    in
    builtins.mapAttrs (
      name: spec:
      prev.${name}.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ final.resolveBuildSystem spec;
      })
    ) buildSystemOverrides;
  pythonSet = pythonBase.overrideScope (
    lib.composeManyExtensions [
      pyproject-build-systems.overlays.wheel
      pyProjectOverlay
      buildSystemOverlay
    ]
  );
  venv = pythonSet.mkVirtualEnv "zotero-mcp-env" workspace.deps.default;
in
writeShellScriptBin "zotero-mcp" ''
  exec ${venv}/bin/zotero-mcp "$@"
''
