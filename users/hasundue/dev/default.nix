{ pkgs, ... }:

{
  imports = [
    ./deno.nix
  ];

  home = {
    packages = with pkgs; [
      act
      bun
      cmake
      emscripten
      stylua
      lua-language-server
      nodejs
      tree-sitter
      zig
      zls
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
