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

  # Required for Steam to work in niri (via xwayland-satellite)
  environment.systemPackages = with pkgs; [
    xwayland-satellite
  ];
}
