{ pkgs }:

{
  forEachCorner = v: {
    top-left = v;
    top-right = v;
    bottom-left = v;
    bottom-right = v;
  };

  overviewAwareMove = pkgs.writeShellScript "niri-overview-aware-move" ''
    direction="$1"

    state=$(${pkgs.niri}/bin/niri msg overview-state)

    if [[ "$state" == *"open"* ]]; then
      case "$direction" in
        "left")
          ${pkgs.niri}/bin/niri msg action move-workspace-to-monitor-left
          ;;
        "right")
          ${pkgs.niri}/bin/niri msg action move-workspace-to-monitor-right
          ;;
      esac
    else
      case "$direction" in
        "left")
          ${pkgs.niri}/bin/niri msg action move-column-left
          ;;
        "right")
          ${pkgs.niri}/bin/niri msg action move-column-right
          ;;
        "up")
          ${pkgs.niri}/bin/niri msg action move-window-up
          ;;
        "down")
          ${pkgs.niri}/bin/niri msg action move-window-down
          ;;
      esac
    fi
  '';
}
