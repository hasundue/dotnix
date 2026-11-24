{
  config,
  lib,
  pkgs,
  ...
}:

let
  # The RK61 identifies itself differently over Bluetooth and USB.
  rk61DeviceNames = [
    "BT5.0 KB Keyboard"
    "SINO WEALTH Gaming KB "
    "SINO WEALTH Gaming KB  System Control"
    "SINO WEALTH Gaming KB  Consumer Control"
    "SINO WEALTH Gaming KB  Keyboard"
  ];
  rk61DevCfgNames = lib.concatStringsSep " " (map (name: "\"${name}\"") rk61DeviceNames);

  chordTimeout = 200;

  # F13 is seen by fcitx5 as Tools, its DeactivateKeys. Deactivation is
  # idempotent, so the command key after the prefix is never eaten as preedit.
  prefix = "(macro F13 C-spc)";

  prefixChords = ''
    (defchordsv2
      (caps spc) ${prefix} ${toString chordTimeout} first-release ()
      (lctl spc) ${prefix} ${toString chordTimeout} first-release ()
      (rctl spc) ${prefix} ${toString chordTimeout} first-release ()
    )
  '';
in
{
  services.kanata = {
    enable = true;
    # The two instances select disjoint devices with linux-dev-names-{in,exclude},
    # so the module's generic warning about multiple empty `devices` lists is
    # expected here.
    keyboards = {
      # Right Shift tap → Up arrow, hold → right Shift
      # Targets only the RK61 by device name
      rk61 = {
        devices = [ ];
        extraDefCfg = ''
          linux-dev-names-include (${rk61DevCfgNames})
          process-unmapped-keys yes
          concurrent-tap-hold yes
        '';
        config = ''
          (defsrc
            caps
            lctl
            rshift
            lsft
            /
            ralt
            comp
            rctl
            spc)

          (deflayermap (default-layer)
            caps lctl
            lctl lctl
            rshift (tap-hold 150 100 up rshift)
            lsft   _
            /      /
            ralt   left
            comp   down
            rctl   rght
            spc    spc
          )

          ${prefixChords}
        '';
      };

      # Every other keyboard. The RK61's arrow-key remaps stay scoped to rk61;
      # the two instances grab disjoint device sets.
      default = {
        devices = [ ];
        extraDefCfg = ''
          linux-dev-names-exclude (${rk61DevCfgNames})
          process-unmapped-keys yes
          concurrent-tap-hold yes
        '';
        config = ''
          (defsrc
            caps
            lctl
            rctl
            spc)

          (deflayermap (default-layer)
            caps lctl
            lctl lctl
            rctl rctl
            spc  spc
          )

          ${prefixChords}
        '';
      };
    };
  };

  # CapsLock→Ctrl lives in ./inputs.nix so it survives disabling kanata.

  # Restart kanata when the RK61 reconnects — inotify can miss it after
  # frequent Bluetooth/USB disconnects/reconnects
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="input", ATTRS{name}=="BT5.0 KB Keyboard", RUN+="${pkgs.systemd}/bin/systemctl restart kanata-rk61.service"
    ACTION=="add", SUBSYSTEM=="input", ATTRS{name}=="SINO WEALTH Gaming KB*", RUN+="${pkgs.systemd}/bin/systemctl restart kanata-rk61.service"
  '';

  # /dev/uinput has ACL restrictions (steam uaccess rule), so DynamicUser
  # doesn't get access even with SupplementaryGroups=uinput.
  # Run as the normal user who already has ACL-granted access.
  systemd.services = {
    kanata-rk61 = {
      restartTriggers = [ config.services.kanata.keyboards.rk61.configFile ];
      serviceConfig = {
        User = lib.mkForce "hasundue";
        DynamicUser = lib.mkForce false;
        PrivateUsers = lib.mkForce false;
      };
    };
    kanata-default = {
      restartTriggers = [ config.services.kanata.keyboards.default.configFile ];
      serviceConfig = {
        User = lib.mkForce "hasundue";
        DynamicUser = lib.mkForce false;
        PrivateUsers = lib.mkForce false;
      };
    };
  };
}
