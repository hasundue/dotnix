{ pkgs, ... }:

{
  imports = [
    ./deno.nix
  ];

  home = {
    packages = with pkgs; [
      # runtimes
      bun
      nodejs
      nodePackages.yarn
      zig

      # tools
      act
      bump
      cmake
      emscripten
      tree-sitter
    ];
  };

  programs.gitui = {
    enable = true;
    keyConfig = builtins.readFile ./gitui.ron;
  };

  programs.gh = {
    enable = true;
    settings = {
      prompt = "disabled";
    };
    gitCredentialHelper.enable = false;
  };
}
