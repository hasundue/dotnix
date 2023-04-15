{ config, lib, pkgs, ... }: 

let
  font = "FiraCode Nerd Font";
in
{
  programs.home-manager.enable = true;

  home.stateVersion = "22.11";

  home.username = "shun";
  home.homeDirectory = "/home/shun";

  fonts.fontconfig.enable = true;

  home.keyboard = {
    options = [ "ctrl:nocaps" ];
  };

  xresources = {
    extraConfig = "Xft.dpi:96";
  };

  xsession = {
    enable = true;

    windowManager.xmonad = {
      enable = true;
      enableContribAndExtras = true;
      config = ./conf/xmonad.hs;
    };
  };

  programs.xmobar = {
    enable = true;
    extraConfig = builtins.readFile ./conf/xmobar.hs;
  };

  programs.vim = {
    enable = true;
    extraConfig = ''
      set noswapfile
    '';
  };

  programs.neovim.enable = true;

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
    };
  };

  programs.alacritty = {
    enable = true;
    settings = {
      env = {
        SHELL = "zsh";
        TERM = "xterm-256color";
      };
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

  programs.chromium = {
    enable = true;
    commandLineArgs = [
      "--force-dark-mode"
      "--enable-features=WebUIDarkMode"
    ];
  };

  home.packages = with pkgs; [ 
    dmenu
    steam
  ];
}
