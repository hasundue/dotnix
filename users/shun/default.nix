{ pkgs, stateVersion, ... }: 

{
  imports = [
    ./wayland.nix
    ./alacritty.nix
  ];

  programs.home-manager.enable = true;

  home = {
    inherit stateVersion;

    username = "shun";
    homeDirectory = "/home/shun";

    packages = (with pkgs; [ 
        # essensials
        neovim
        unzip
        wget
        ripgrep
        nil
        xdg-utils

        # development
        deno
        zig
        bun
        nodejs
        nodePackages.wrangler
        nodePackages.yarn
        buildkit # required by cicada

        # wayland
        wl-clipboard
        grim
        slurp
        tofi

        # apps
        (vivaldi.override {
          proprietaryCodecs = true;
        })
        vieb
        _1password-gui

        # communication
        slack
        slack-term
        zoom-us
        discord

        # entertainment
        spotify
        steam
        steamcmd
        steam-tui
    ]);

    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.deno/bin"
    ];

    sessionVariables = {
      EDITOR = "nvim";
      BROWSER = "vivaldi";
      NIXOS_OZONE_WL = 1;
    };

    file = {
      ".config/slack-term/config".text = builtins.toJSON {
        slack_token = "xoxe.xoxp-1-Mi0yLTMyMjg4MjE1Nzc4MS0yMzkxNTM4MTY5NDU2LTQxMzQwNzE4MTA4MzctNTE4MjM2NzYwMTQ0My02OThiZDhjOGQ3MTFhMWIzYmMzZWVkNmZjMmY1N2M1N2Y0YThlNjhiZTg2OWU2NGI1OTk3NjI2YTRjYzc0MTE2";
        slack_loglevel = "info";
      };
    };
  };

  fonts.fontconfig.enable = true;

  programs.vim = {
    enable = true;
    settings = {
      expandtab = true;
      number = true;
      shiftwidth = 2;
    };
    extraConfig = ''
      set noswapfile
    '';
  };

  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableSyntaxHighlighting = true;
    defaultKeymap = "vicmd";
    dotDir = ".config/zsh";
    initExtra = ''
      bindkey -L
    '';
    prezto = {
      enable = true;
      prompt.theme = "pure";
    };
    shellAliases = {
      ll = "ls -l";
      nbuild = "sudo nixos-rebuild switch --flake .";
      nupdate = "nix flake update . && sudo nixos-rebuild switch --flake .";
      nv = "nvim";
    };
    shellGlobalAliases = {
      vieb = "vieb --enable-features=UseOzonePlatform --ozone-platform=wayland";
    };
  };

  programs.gh = {
    enable = true;
    enableGitCredentialHelper = false;
    settings = {
      prompt = "disabled";
    };
  };

  programs.git = {
    enable = true;
    userEmail = "hasundue@gmail.com";
    userName = "hasundue";
    ignores = [ ".env" ];
    aliases = {
      co = "checkout";
    };
    extraConfig = {
      credential."https://github.com".helper = "!gh auth git-credential";
      init = {
        defaultBranch = "main";
      };
      push.autoSetupRemote = true;
    };
  };

  programs.gitui = {
    enable = true;
    keyConfig = builtins.readFile ./gitui.ron;
  };
}
