{ config, lib, pkgs, ... }: 

let
  font = "FiraCode Nerd Font";
in
{
  home.username = "shun";
  home.homeDirectory = "/home/shun";

  home.stateVersion = "22.11";

  programs.home-manager.enable = true;

  fonts.fontconfig.enable = true;

  programs.vim.enable = true;
  programs.neovim.enable = true;

  home.keyboard = {
    options = [ "ctrl:nocaps" ];
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
      nbuild = "nixos-rebuild switch --flake .";
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

  home.packages = with pkgs; [ 
    dmenu
    steam
  ];
}
