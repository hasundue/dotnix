{ pkgs, nix-colors, ... }: 

let
  font = "FiraCode Nerd Font";
  colors = nix-colors.colorSchemes.nord.colors;
in
{
  programs.home-manager.enable = true;

  home.stateVersion = "23.05";

  home.username = "shun";
  home.homeDirectory = "/home/shun";

  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk
    ];
  };

  wayland.windowManager.sway = {
    enable = true;
    config = {
      gaps = {
        smartBorders = "on";
        smartGaps = true;
        inner = 10;
      };
      input = {
        "*" = {
          xkb_options = "ctrl:nocaps";
        };
      };
      menu = "NIXOS_OZONE_WL=1 wofi --show run";
      output = {
        eDP-1 = {
          scale = "1.2";
          scale_filter = "nearest";
          subpixel = "rgb";
        };
      };
      fonts = {
        names = [ "Source Han Sans" ];
        style = "Heavy";
        size = 10.0;
      };
      modifier = "Mod4";
      terminal = "alacritty";
    };
    wrapperFeatures.gtk = true;
  };

  home.pointerCursor = {
    name = "Nordzy-cursors";
    package = pkgs.nordzy-cursor-theme;
    size = 16;
    gtk.enable = true;
  };

  fonts.fontconfig.enable = true;

  gtk = {
    enable = true;
    font = {
      name = "Source Han Sans";
      size = 11;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-xft-antialias = 1;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "slight";
      gtk-xft-rgba = "rgb";
    };
    theme = {
      name = "Nordic-darker";
      package = pkgs.nordic;
    };
    cursorTheme = {
      name = "Nordzy-cursors";
      size = 26;
    };
  };

  qt = {
    enable = true;
    platformTheme = "gtk";
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

  programs.alacritty = {
    enable = true;
    settings = {
      env = {
        SHELL = "zsh";
      };
      decorations = "none";
      opacity = 0.9;
      font = {
        normal = { family = font; style = "Regular"; };
        bold = { family = font; style = "Bold"; };
        italic = { family = font; style = "Oblique"; };
        size = 10.0;
      };
      colors = {
        background = "#${colors.base00}";
        foreground = "#${colors.base04}";
      };
      window = {
        padding = { x = 10; y = 10; };
        dynamic_padding = true;
      };
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
    keyConfig = builtins.readFile ./conf/gitui.ron;
  };

  home.packages = (with pkgs; [ 
    neovim
    unzip
    nodejs
    deno
    zig
    ghc
    nil # a language server for Nix
    haskell-language-server
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
  ]);
}
