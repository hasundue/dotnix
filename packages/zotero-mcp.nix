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
    rev = "db1aa904b72db4ef645b4a57197883d2e967bd0d";
    hash = "sha256-+o4LtiSzs6GhU1V8sJFiyoZNWUP9eVO/B+XPOv1+5lA=";
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
