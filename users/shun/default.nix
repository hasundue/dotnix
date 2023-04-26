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
        neovim
        unzip
        nil
        nodejs
        deno
        bun
        zig
        wl-clipboard
        wofi
        (vivaldi.override {
          proprietaryCodecs = true;
        })
        google-chrome
        slack
        zoom-us
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
      NIXOS_OZONE_WL = 1;
    };
  };

  fonts.fontconfig.enable = true;

  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk
    ];
  };

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
    prezto = {
      enable = true;
      prompt.theme = "pure";
    };
    shellAliases = {
      ll = "ls -l";
      nbuild = "sudo nixos-rebuild switch --flake .";
      nv = "nvim";
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
    aliases = {
      co = "checkout";
    };
    extraConfig = {
      credential."https://github.com".helper = "!gh auth git-credential";
      init = {
        defaultBranch = "main";
      };
    };
    userEmail = "hasundue@gmail.com";
    userName = "hasundue";
  };

  programs.gitui = {
    enable = true;
    keyConfig = builtins.readFile ./gitui.ron;
  };
}
