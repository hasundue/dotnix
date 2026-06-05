{
  pkgs,
  ...
}:

{
  programs.steam = {
    enable = true;
    package = pkgs.steam.override {
      extraArgs = "-system-composer"; # Prevent a fully black window
    };
  };

  programs.gamescope.enable = true;

  environment = {
    sessionVariables = {
      PROTON_ENABLE_WAYLAND = "1";
    };
  };

  hardware.xpadneo.enable = true;
}
