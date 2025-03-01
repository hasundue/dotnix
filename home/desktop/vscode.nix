{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;

    mutableExtensionsDir = false;

    profiles.default = {
      enableExtensionUpdateCheck = false;
      enableUpdateCheck = false;

      extensions = with pkgs.vscode-extensions; [
        saoudrizwan.claude-dev
      ];
    };
  };
}
