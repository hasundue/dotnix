{ pkgs, ... }:

let
  nv = pkgs.writeShellScriptBin "nv" ''
    if [ -d ~/nvim ]; then
      exec nix run ~/nvim -- "$@"
    else
      exec nvim "$@"
    fi
  '';
in

{
  programs.git.extraConfig.core.editor = "nvim";

  home = {
    packages = [
      (pkgs.mkNeovim {
        modules = with pkgs.mkNeovim.modules; [
          core
          clipboard
          copilot
          deno
          nix
          lua
        ];
      })
      nv
    ];
    sessionVariables.EDITOR = "nv";
  };
}
