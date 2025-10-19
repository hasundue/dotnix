{
  pkgs,
  ...
}:

{
  programs.steam = {
    enable = true;
  };

  programs.gamescope.enable = true;

  # Required for Steam to work in niri (via xwayland-satellite)
  environment.systemPackages = with pkgs; [
    xwayland-satellite
  ];
}
