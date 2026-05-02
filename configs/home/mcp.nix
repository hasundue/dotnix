{ ... }:
{
  mcp-servers.programs = {
    github = {
      enable = true;
      passwordCommand = {
        GITHUB_PERSONAL_ACCESS_TOKEN = [
          "gh"
          "auth"
          "token"
        ];
      };
    };
    nixos.enable = true;
  };
}
