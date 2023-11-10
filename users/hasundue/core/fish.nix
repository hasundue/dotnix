{ pkgs, ... }: {
  programs.fish = {
    enable = true;
    plugins = [
      { name = "autopair"; inherit (pkgs.fishPlugins.autopair) src; }
    ];
  };
}

