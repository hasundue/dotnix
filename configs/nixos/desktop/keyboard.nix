{
  # CapsLock→Ctrl at the kernel level via hwdb.
  # This is more reliable than niri's ctrl:nocaps for games that bypass
  # compositor-level XKB options.
  #
  # Kept separate from kanata.nix so the remap survives disabling kanata.
  services.udev.extraHwdb = ''
    # Internal ThinkPad keyboard (AT/PS2)
    evdev:atkbd:dmi:bvn*:bvr*:bd*:svnLENOVO*:pn20HRCTO1WW:*
     KEYBOARD_KEY_3a=leftctrl

    # HHKB Professional (USB HID)
    evdev:input:b0003v0853p0100*
     KEYBOARD_KEY_70039=leftctrl
  '';
}
