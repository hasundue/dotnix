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

  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        sidePanelWidth = 0.5;
      };
      keybinding = {
        commits = {
          revertCommit = "<disabled>";
        };
      };
      customCommands = [
        {
          key = "t";
          context = "commits";
          command = "git revert {{.SelectedCommit.Sha}} --no-edit && git commit --amend -m \"revert: $(git log --format=%B -n 1 {{.SelectedCommit.Sha}} | head -1)\"";
          description = "Revert";
        }
      ];
    };
  };

  home = {
    packages = with pkgs; [
      ghq
    ];
    shellAliases = {
      "lg" = "lazygit";
    };
  };
}
