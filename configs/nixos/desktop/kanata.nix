{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.kanata = {
    enable = true;
    keyboards = {
      # Right Shift tap → Up arrow, hold → right Shift
      # Targets only the Bluetooth keyboard by device name
      bt-keyboard = {
        # No devices = use linux-dev-names-include in extraDefCfg instead
        devices = [ ];
        extraDefCfg = ''
          linux-dev-names-include ("BT5.0 KB Keyboard")
          process-unmapped-keys yes
        '';
        config = ''
          (defsrc
            caps
            rshift
            lsft
            /
            ralt
            comp
            rctl)

          (deflayermap (default-layer)
            caps lctl
            rshift (tap-hold 150 100 up rshift)
            lsft   _
            /      /
            ralt   left
            comp   down
            rctl   rght
          )
        '';
      };
    };
  };

  # CapsLock→Ctrl lives in ./keyboard.nix so it survives disabling kanata.

  # Restart kanata when the BT keyboard reconnects — inotify can miss it after
  # frequent Bluetooth disconnects/reconnects
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="input", ATTRS{name}=="BT5.0 KB Keyboard", RUN+="${pkgs.systemd}/bin/systemctl restart kanata-bt-keyboard.service"
  '';

  # /dev/uinput has ACL restrictions (steam uaccess rule), so DynamicUser
  # doesn't get access even with SupplementaryGroups=uinput.
  # Run as the normal user who already has ACL-granted access.
  systemd.services."kanata-bt-keyboard" = {
    restartTriggers = [
      config.services.kanata.keyboards.bt-keyboard.configFile
    ];
    serviceConfig = {
      User = lib.mkForce "hasundue";
      DynamicUser = lib.mkForce false;
      PrivateUsers = lib.mkForce false;
    };
  };
}
