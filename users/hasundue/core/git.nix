{
  programs.git = {
    enable = true;
    ignores = [ 
      ".env"
      "dist/"
      "vendor/"
      "node_modules"
    ];
    userEmail = "hasundue@gmail.com";
    userName = "hasundue";
    extraConfig = {
      credential."https://github.com".helper = "!gh auth git-credential";
      init = {
        defaultBranch = "main";
      };
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };

  home.shellAliases = rec {
    g = "git";
    ga = "git add";
    gaa = "${ga} --all";
    gb = "git branch";
    gd = "git diff";
    gf = "git fetch --all --prune --tags";
    gch = "git checkout";
    gcl = "git clone";
    gco = "git commit";
    gcom = "${gco} --message";
    gcoa = "${gco} --amend";
    gcoan = "${gco} --amend --no-edit";
    gpl = "git pull --rebase";
    gps = "git push";
    gpsf = "${gps} --force-with-lease";
    grb = "git rebase";
    grba = "${grb} --abort";
    grbc = "${grb} --continue";
    gst = "git status";
    gsw = "git switch";
  };
}
