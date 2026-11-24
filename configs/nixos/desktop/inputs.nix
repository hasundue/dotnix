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

    # Logitech ERGO M575 / M575S is a trackball, not a plain mouse.
    # Niri uses ID_INPUT_TRACKBALL to select the input.trackball settings.
    id-input:modalias:input:b0005v046DpB027*
     ID_INPUT_TRACKBALL=1
     ID_INPUT=1
  '';
}
