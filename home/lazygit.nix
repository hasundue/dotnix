{ ... }:

{
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

  home.shellAliases = {
    "lg" = "lazygit";
  };
}
