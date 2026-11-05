{
  lib,
  pkgs,
  ...
}:

let
  # Must match `networking.networkmanager.settings.connectivity.uri` in
  # configs/hosts/x1carbon/default.nix. NetworkManager does not expose the
  # portal's address over D-Bus, so the probe is repeated here to learn where
  # the login page actually lives.
  probeUri = "http://connectivity-check.ubuntu.com/";

  portalOpen = pkgs.writeShellApplication {
    name = "portal-open";
    runtimeInputs = with pkgs; [
      curl
      networkmanager
      xdg-utils
    ];
    text = ''
      probe_uri=${lib.escapeShellArg probeUri}

      # Print the URL worth opening. Fails when the probe reached its own URI
      # untouched (online) or when nothing answered at all (offline).
      portal_url() {
        local out code effective
        out=$(curl --silent --location --max-time 10 \
          --output /dev/null --write-out '%{http_code} %{url_effective}' \
          "$probe_uri") || return 1
        code=''${out%% *}
        effective=''${out#* }
        if [ "$code" = 204 ] && [ "$effective" = "$probe_uri" ]; then
          return 1
        fi
        printf '%s\n' "''${effective:-$probe_uri}"
      }

      # Resolve through the desktop's default browser rather than naming one:
      # xdg-open goes through the XDG portal and reads mimeapps.list. The portal
      # starts the browser with its own environment, so this also works when the
      # service was started before the compositor imported its variables into
      # the user manager.
      open_portal() {
        local url=$1
        if xdg-open "$url" >/dev/null 2>&1; then
          printf 'opened %s\n' "$url"
        else
          printf 'could not open %s\n' "$url"
        fi
      }

      handle() {
        local state=$1 url
        case "$state" in
          portal)
            # NetworkManager already saw the probe intercepted. Prefer the
            # redirect target, but fall back to the probe URI itself: the
            # portal intercepts that request in the browser just the same.
            url=$(portal_url) || url=$probe_uri
            open_portal "$url"
            ;;
          limited)
            # "limited" also covers plain breakage (no DNS, no route), so only
            # open when the probe came back with something unexpected.
            url=$(portal_url) || return 0
            open_portal "$url"
            ;;
        esac
      }

      # NetworkManager only reports "portal" once connectivity checking is
      # enabled, so watch for changes and start from the current state: the
      # machine may well boot while already behind a portal.
      state=$(nmcli --terse --fields CONNECTIVITY general 2>/dev/null || true)
      if [ -n "$state" ]; then
        handle "$state"
      fi

      nmcli monitor | while IFS= read -r line; do
        case "$line" in
          "Connectivity is now 'portal'") handle portal ;;
          "Connectivity is now 'limited'") handle limited ;;
        esac
      done
    '';
  };
in
{
  home.packages = [ portalOpen ];

  systemd.user.services.portal-login = {
    Unit.Description = "Open the captive portal login page when the network is behind one";
    Service = {
      ExecStart = lib.getExe portalOpen;
      Restart = "always";
      RestartSec = 10;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
