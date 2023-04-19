{ config, lib, pkgs, pkgs-unstable, pkgs-master, nix-colors, ... }: 

let
  font = "FiraCode Nerd Font";
  colors = nix-colors.colorSchemes.nord.colors;
in
{
  programs.home-manager.enable = true;

  home.stateVersion = "22.11";

  home.username = "shun";
  home.homeDirectory = "/home/shun";

  home.keyboard = {
    options = [ "ctrl:nocaps" ];
  };

  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk
    ];
  };

  xsession = {
    enable = true;

    windowManager.xmonad = {
      enable = true;
      enableContribAndExtras = true;
      config = ./conf/xmonad.hs;
    };
  };

  xresources = {
    extraConfig = "Xft.dpi:96";
  };

  home.sessionVariables = {
    GDK_SCALE=1;
    GDK_DPI_SCALE=1.20;
  };

  fonts.fontconfig.enable = true;

  services.xsettingsd.settings = {
    "Xft/Hinting" = true;
    "Xft/HintStyle" = "hintslight";
    "Xft/Antialias" = true;
    "Xft/RGBA" = "rgb";
  };

  gtk = {
    enable = true;
    theme = {
      name = "Nordic-darker";
      package = pkgs.nordic;
    };
  };

  qt = {
    enable = true;
    platformTheme = "gtk";
  };

  programs.xmobar = {
    enable = true;
    extraConfig = builtins.readFile ./conf/xmobar.hs;
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
        normal = {
          family = font;
          style = "Regular";
        };
        bold = {
          family = font;
          style = "Bold";
        };
        italic = {
          family = font;
          style = "Oblique";
        };
        size = 12.0;
      };
      colors = {
        background = "#${colors.base00}";
        foreground = "#${colors.base04}";
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

  programs.autorandr = {
    enable = true;
  };

  programs.gitui = {
    enable = true;
    keyConfig = builtins.readFile ./conf/gitui.ron;
  };

  programs.chromium = {
    enable = true;
    commandLineArgs = [
      "--force-dark-mode"
      "--enable-features=WebUIDarkMode,VaapiVideoDecoder"
    ];
  };

  home.packages = (with pkgs; [ 
    unzip
    nodejs
    ghc
    haskell-language-server
    nil # a language server for Nix
    dmenu
    google-chrome
    slack
    zoom-us
    spotify
    steam
  ]) ++ (with pkgs-unstable; [
    (vivaldi.override {
      proprietaryCodecs = true;
    })
  ]) ++ (with pkgs-master; [
    neovim
    deno
    zig
  ]);
}
