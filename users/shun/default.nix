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
        fd
        unzip
        wget
        ripgrep
        nil
        xdg-utils
        fcitx5
        fcitx5-configtool

        # development
        deno
        zig
        julia
        bun
        nodejs
        nodePackages.wrangler
        nodePackages.yarn
        buildkit # required by cicada
        act

        # wayland
        wl-clipboard
        grim
        slurp
        tofi

        # apps
        (vivaldi.override {
          proprietaryCodecs = true;
        })
        _1password-gui
        marp-cli
        google-chrome

        # communication
        slack
        zoom-us
        discord

        # entertainment
        spotify
        (lutris.override {
          extraPkgs = pkgs: [
            wine
            steam
          ];
        })
    ]);

    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.deno/bin"
    ];

    sessionVariables = {
      EDITOR = "nvim";
      BROWSER = "vivaldi";
      NIXOS_OZONE_WL = 1;
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
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
    defaultKeymap = "vicmd";
    dotDir = ".config/zsh";
    prezto = {
      enable = true;
      editor = {
        dotExpansion = true;
        promptContext = false;
      };
      prompt.theme = "pure";
      utility = {
        safeOps = true;
      };
    };
    shellAliases = {
      ll = "ls -l";
      nv = "nvim";
      nbuild = "sudo nixos-rebuild switch --flake .";
      nupdate = "nix flake update . && nbuild";
    };
    shellGlobalAliases = {
      suspend = "systemctl suspend";
      vieb = "vieb --enable-features=UseOzonePlatform --ozone-platform=wayland";
    };
    syntaxHighlighting = {
      enable = true;
    };
  };

  programs.gh = {
    enable = true;
    settings = {
      prompt = "disabled";
    };
    gitCredentialHelper.enable = false;
  };

  programs.git = {
    enable = true;
    userEmail = "hasundue@gmail.com";
    userName = "hasundue";
    ignores = [ ".env" "dist/" "node_modules" ];
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
