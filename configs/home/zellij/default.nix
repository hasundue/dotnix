{ ... }:
{
  programs.zellij = {
    enable = true;

    settings = {
      default_mode = "locked";
      default_layout = "minimal";

      # Drops the "<session-name>" suffix from the bar.
      ui.pane_frames.hide_session_name = true;
    };

    # Kept as KDL: the attr -> KDL generator would need _children/_props wrappers
    # for every repeated/attribute node, which is longer and less legible here.
    layouts.minimal = ./layouts/minimal.kdl;
  };
}
