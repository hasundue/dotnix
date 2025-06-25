{ config, ... }:

{
  programs.claude-code = {
    enable = true;
    mcp = {
      filesystem = {
        enable = true;
        allowedPaths = [ "/home/hasundue" ];
      };
      git.enable = true;
      github = {
        enable = true;
        baseURL = "https://github.com";
        tokenFilepath = config.age.secrets."github/claude-code".path;
      };
    };
  };

  programs.git.ignores = [
    ".claude/"
  ];
}
