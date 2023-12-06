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

      # language servers
      lua-language-server
      nil
      zls

      # tools
      act
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
