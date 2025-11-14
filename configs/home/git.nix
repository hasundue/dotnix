{ pkgs, ... }:
{
  programs.git = {
    enable = true;
    ignores = [
      "*~"
      ".direnv/"
      ".env"
      ".envrc"
    ];
    settings = {
      fetch.prune = true;
      ghq.root = "~/.cache/ghq";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      user = {
        name = "Shun Ueda";
        email = "hasundue@gmail.com";
      };
    };
  };
  home.packages = with pkgs; [
    ghq
  ];
}
