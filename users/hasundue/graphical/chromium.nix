{
  programs.chromium = {
    commandLineArgs = [
      "--enable-features=UseOzonePlatform"
      "--ozone-platform=wayland"
      "--enable-wayland-ime"
    ];
    enable = true;
    extensions = [
      { id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa"; } # 1Password
      { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # Dark Reader
      { id = "fihnjjcciajhdojfnbdddfaoknhalnja"; } # I don't care about cookies
      { id = "kpgefcfmnafjgpblomihpgmejjdanjjp"; } # nos2x
      { id = "fjdmkanbdloodhegphphhklnjfngoffa"; } # YouTube Auto HD
    ];
  };
}
