{ pkgs, ... }:

{
  programs = {
    git = {
      enable = true;
      userEmail = "hasundue@gmail.com";
      userName = "hasundue";
      extraConfig = {
        credential."https://github.com".helper = "${pkgs.gh}/bin/gh auth git-credential";
        init = {
          defaultBranch = "main";
        };
        pull.rebase = true;
        push.autoSetupRemote = true;
      };
    };

    lazygit = {
      enable = true;
      settings = {
        gui = {
          sidePanelWidth = 0.5;
        };
      };
    };
  };
}
