{ lib, ... }:

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
        '';
        config = ''
          (defsrc
            rshift
            up)

          (deflayermap (default-layer)
            rshift (tap-hold 150 100 up rshift)
            up     /
          )
        '';
      };
    };
  };

  # /dev/uinput has ACL restrictions (steam uaccess rule), so DynamicUser
  # doesn't get access even with SupplementaryGroups=uinput.
  # Run as the normal user who already has ACL-granted access.
  systemd.services."kanata-bt-keyboard" = {
    serviceConfig = {
      User = lib.mkForce "hasundue";
      DynamicUser = lib.mkForce false;
      PrivateUsers = lib.mkForce false;
    };
  };
}
