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
    userEmail = "hasundue@gmail.com";
    userName = "Shun Ueda";
    extraConfig = {
      # credential."https://github.com".helper = "${pkgs.gh}/bin/gh auth git-credential";
      fetch.prune = true;
      init = {
        defaultBranch = "main";
      };
      pull.rebase = true;
      push.autoSetupRemote = true;
      ghq.root = "~/dev";
    };
  };

  home.packages = with pkgs; [
    ghq
  ];
}
