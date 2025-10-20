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
      # credential."https://github.com".helper = "${pkgs.gh}/bin/gh auth git-credential";
      fetch.prune = true;
      ghq.root = "~/dev";
      init = {
        defaultBranch = "main";
      };
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
