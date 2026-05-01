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
    owner = "oOo0oOo";
    repo = "lean-lsp-mcp";
    rev = "v0.26.1";
    hash = "sha256-OHbD6HujkXsqe8XpNr1bn+Pel2tbkX7tBapCcUe234o=";
  };
  pythonBase = callPackage pyproject-nix.build.packages {
    inherit python;
  };
  workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = src; };
  pyProjectOverlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };
  pythonSet = pythonBase.overrideScope (
    lib.composeManyExtensions [
      pyproject-build-systems.overlays.wheel
      pyProjectOverlay
    ]
  );
  venv = pythonSet.mkVirtualEnv "lean-lsp-mcp-env" workspace.deps.default;
in
writeShellScriptBin "lean-lsp-mcp" ''
  exec ${venv}/bin/lean-lsp-mcp "$@"
''
