final: prev:
let
  lib = final.lib;
  python = final.python312;
  src = final.fetchFromGitHub {
    owner = "kujenga";
    repo = "zotero-mcp";
    rev = "db1aa904b72db4ef645b4a57197883d2e967bd0d";
    hash = "sha256-+o4LtiSzs6GhU1V8sJFiyoZNWUP9eVO/B+XPOv1+5lA=";
  };
  pythonBase = prev.callPackage final.lib.pyproject-nix.build.packages {
    inherit python;
  };
  workspace = final.lib.uv2nix.workspace.loadWorkspace { workspaceRoot = src; };
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
      final.lib.pyproject-build-systems.overlays.wheel
      pyProjectOverlay
      buildSystemOverlay
    ]
  );
  venv = pythonSet.mkVirtualEnv "zotero-mcp-env" workspace.deps.default;
in
{
  zotero-mcp = final.writeShellScriptBin "zotero-mcp" ''
    exec ${venv}/bin/zotero-mcp "$@"
  '';
}
