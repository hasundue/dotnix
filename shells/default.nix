{
  pkgs,
  treefmt-nix,
  git-hooks-nix,
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  dprintMarkdown = pkgs.fetchurl {
    url = "https://plugins.dprint.dev/markdown-0.29.0.wasm";
    hash = "sha256-cUrqdVXdmDGGG+Rm2osmstkjFtPN5VDvPh9jsx9OowI=";
  };
  treefmt = treefmt-nix.lib.mkWrapper pkgs {
    projectRootFile = "flake.nix";
    programs = {
      dprint = {
        enable = true;
        includes = [ "*.md" ];
        settings = {
          lineWidth = 80;
          plugins = [ (toString dprintMarkdown) ];
          markdown = {
            textWrap = "maintainAndWrap";
            wrapUnspacedScripts = true;
            wrapCodeSpans = false;
          };
        };
      };
      nixfmt.enable = true;
      oxfmt = {
        enable = true;
        excludes = [ "*.md" ];
      };
    };
  };
  git-hooks = git-hooks-nix.lib.${system}.run {
    src = ../.;
    hooks = {
      treefmt = {
        enable = true;
        package = treefmt;
      };
      gitleaks = {
        enable = true;
        package = pkgs.gitleaks;
      };
    };
  };
in
pkgs.mkShellNoCC {
  packages = with pkgs; [
    act
    nil
    nixfmt
    oxfmt
    treefmt
  ];
  shellHook = git-hooks.shellHook;
}
// {
  inherit treefmt;
  inherit (git-hooks.config) configFile;
}
