{
  config,
  lib,
  pkgs,
  ...
}:

# Focus events only ever reach the compositor, and mako has no way to ask for
# them (mako.5 has no focus-based dismissal), so a small helper bridges the two:
# it follows niri's event stream and dismisses the notifications of an app when
# one of its windows gains focus, which is what web apps in Chrome do for
# themselves from JavaScript.
#
# focus-dismiss.sh does the watching; this module owns the name table it matches
# against and the unit that keeps it running.
let
  cfg = config.services.mako.focusDismiss;

  aliasesFile = pkgs.writeText "mako-focus-dismiss-aliases.json" (builtins.toJSON cfg.aliases);

  focusDismiss = pkgs.writeShellApplication {
    name = "mako-focus-dismiss";
    runtimeInputs = [
      pkgs.jq
      pkgs.mako
      pkgs.niri
    ];
    text = builtins.replaceStrings [ "@aliases@" ] [ "${aliasesFile}" ] (
      builtins.readFile ./focus-dismiss.sh
    );
  };
in
{
  options.services.mako.focusDismiss = {
    enable =
      lib.mkEnableOption "dismissing an app's notifications when one of its windows gains focus"
      // {
        default = true;
      };

    aliases = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = { };
      example = {
        "sh.waku" = [ "Waku" ];
      };
      description = ''
        Notification names to accept for a window's `app-id`, for apps that call
        themselves different things on each side. The matcher already ignores
        case and punctuation, so `google-chrome` needs no entry for "Google
        Chrome" nor `Slack` for "slack"; only genuinely different names belong
        here.
      '';
    };
  };

  config = lib.mkIf (cfg.enable && config.services.mako.enable) {
    systemd.user.services.mako-focus-dismiss = {
      Unit = {
        Description = "Dismiss an app's notifications when its window gains focus";
        ConditionEnvironment = "WAYLAND_DISPLAY";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = lib.getExe focusDismiss;
        # niri's event stream ends when the compositor restarts.
        Restart = "always";
        RestartSec = 2;
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
