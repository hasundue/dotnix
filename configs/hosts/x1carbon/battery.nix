{
  config,
  lib,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.dotnix.battery;

  thresholds = start: stop: {
    START_CHARGE_THRESH_BAT0 = start;
    STOP_CHARGE_THRESH_BAT0 = stop;
  };
in
{
  options.dotnix.battery = {
    chargeThresholds = mkOption {
      type = types.nullOr (
        types.submodule {
          options = {
            start = mkOption {
              type = types.ints.between 0 100;
              description = "Battery level in percent at which charging starts again.";
            };
            stop = mkOption {
              type = types.ints.between 0 100;
              description = "Battery level in percent at which charging stops.";
            };
          };
        }
      );
      default = null;
      description = ''
        Charge window for BAT0, written to TLP's {option}`START_CHARGE_THRESH_BAT0`
        and {option}`STOP_CHARGE_THRESH_BAT0`. Null leaves the firmware value in
        place, which on this machine is 75/80.

        The window is a compromise. A narrow one such as 75/80 slows wear, but
        the pack never reaches its true full, so the gauge stops learning the
        top endpoint and starts over-reporting: this machine ended up cutting
        power at twenty-something percent. 85/90 keeps most of the wear benefit
        and still exercises enough of the top to stay honest.
      '';
    };

    calibration = mkEnableOption ''
      battery gauge calibration mode for BAT0.

      The pack's fuel gauge derives its full-charge estimate from the top and
      bottom endpoints it has actually seen. Cycling inside a narrow charge
      window leaves both stale, the gauge over-reports, and the machine cuts
      power while it still shows twenty-something percent. This mode opens the
      window to 0/100 so the pack reaches its true full, and makes UPower ignore
      the critical action so the discharge runs down to the true empty cutoff
      instead of sleeping on the way. It therefore overrides
      {option}`dotnix.battery.chargeThresholds` while on.

      One cycle: charge to 100% and leave it on the charger for a while, unplug
      and stay awake until the machine powers itself off, leave it off the
      charger for a few hours, then charge to 100% again without powering on.
      On this host the discharge has reached 8% at 9.0 V, and the following
      full charge re-learned the full-charge capacity from 32.62 Wh to
      38.53 Wh, which is the real number: the old one was the 80% stop point.

      Reach it through the `calibration` specialisation declared next to
      {option}`dotnix.battery.chargeThresholds`: the cycle ends with the machine
      powering itself off, so booting back into the base system reverts the mode
      with nobody having to remember. Keep it off in the base system: calibration
      burns full cycles, and with the action ignored nothing stops the machine
      before the EC cut-off.
    '';
  };

  config = lib.mkMerge [
    {
      # One-shot bridges from the waybar click to root. `systemctl start` asks
      # for a password through polkit, and the rule below answers yes for these
      # two units and this user, so a click is enough.
      systemd.services = {
        # Leaving the house: a full pack matters more than the wear the charge
        # window avoids.
        battery-fullcharge = {
          description = "Charge BAT0 to 100% once, overriding the charge window";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${config.services.tlp.package}/sbin/tlp fullcharge";
          };
        };

        # Clicked by mistake, or the trip got cancelled: re-apply /etc/tlp.conf,
        # which puts the window back. `tlp start` writes the thresholds, so the
        # numbers stay in one place.
        battery-restore = {
          description = "Restore the configured BAT0 charge window";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${config.services.tlp.package}/sbin/tlp start";
          };
        };
      };

      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          var unit = action.lookup("unit");
          if (action.id == "org.freedesktop.systemd1.manage-units"
              && (unit == "battery-fullcharge.service" || unit == "battery-restore.service")
              && subject.user == "hasundue") {
            return polkit.Result.YES;
          }
        });
      '';
    }

    {
      assertions = [
        {
          assertion =
            cfg.calibration
            || cfg.chargeThresholds == null
            || cfg.chargeThresholds.start < cfg.chargeThresholds.stop;
          message = ''
            dotnix.battery.chargeThresholds.start must be lower than
            dotnix.battery.chargeThresholds.stop.
          '';
        }
      ];
    }

    (mkIf (cfg.chargeThresholds != null) {
      # TLP writes the pair at every start and again after resume, so a firmware
      # value cannot outlive a boot.
      services.tlp.settings = thresholds cfg.chargeThresholds.start cfg.chargeThresholds.stop;
    })

    (mkIf cfg.calibration {
      # mkForce, not a plain definition: calibrating is exactly the decision to
      # ignore the window, so it must win over chargeThresholds without the
      # caller having to unset it.
      services.tlp.settings = {
        START_CHARGE_THRESH_BAT0 = lib.mkForce 0;
        STOP_CHARGE_THRESH_BAT0 = lib.mkForce 100;
      };

      services.upower = {
        # "Ignore" is the whole point: at the critical level UPower would
        # otherwise try to hybrid-sleep, and this host has no swap to make that
        # work, so the discharge never reaches the EC cut-off.
        allowRiskyCriticalPowerAction = true;
        criticalPowerAction = "Ignore";
      };
    })

    (mkIf config.services.upower.enable {
      # UPower.conf is a data file, not a unit, so a switch would not restart
      # the daemon on its own. Keep this outside the calibration branch: turning
      # calibration off has to reach the running daemon as well, or it keeps
      # "Ignore" while the file says otherwise.
      systemd.services.upower.restartTriggers = [
        config.environment.etc."UPower/UPower.conf".source
      ];
    })
  ];
}
