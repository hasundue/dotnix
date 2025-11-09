{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;

    mutableExtensionsDir = false;

    profiles.default = {
      enableExtensionUpdateCheck = false;
      enableUpdateCheck = false;

      extensions = with pkgs.vscode-extensions; [
        golang.go
        github.copilot
        mkhl.direnv
        bbenoist.nix
        saoudrizwan.claude-dev
      ];
    };
  };
}
