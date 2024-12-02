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
      credential."https://github.com".helper = "${pkgs.gh}/bin/gh auth git-credential";
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
    settings.gui.sidePanelWidth = 0.5;
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
