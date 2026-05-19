{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./nix.nix
  ];

  i18n.defaultLocale = "en_US.UTF-8";

  environment = {
    pathsToLink = [
      "/bin"
      "/share/bash"
    ];
    systemPackages = with pkgs; [
      bash
      vim
    ];
    # Native .node addons (decibri, sherpa-onnx-node) loaded via dlopen()
    # by Node.js don't see nix-ld libraries. alsa-lib needed for microphone.
    # sessionVariables propagate via PAM to all sessions (greetd → niri → terminal).
    # Conflicts with another module setting LD_LIBRARY_PATH would fail at eval.
    sessionVariables = {
      LD_LIBRARY_PATH = lib.makeSearchPath "lib" [ pkgs.alsa-lib ];
    };
  };

  home-manager = {
    backupFileExtension = "backup";
    useGlobalPkgs = true;
    useUserPackages = true;
    users.hasundue = {
      imports = [ ../home ];
    };
  };

  programs = {
    fish.enable = true;
    nix-ld = {
      enable = true;
      # https://github.com/cloudflare/workerd/discussions/1515#discussioncomment-10024333
      libraries = with pkgs; [
        stdenv.cc.cc
        zlib
        fuse3
        icu
        nss
        openssl
        curl
        expat

        # rpiv-voice: native deps for sherpa-onnx-node (STT)
        alsa-lib
      ];
    };
  };

  security = {
    sudo.enable = true;
  };

  services = {
    openssh.enable = true;
  };

  system = {
    stateVersion = "26.05";
  };

  users.users.hasundue = {
    createHome = true;
    description = "Shun Ueda";
    group = "hasundue";
    extraGroups = [
      "wheel"
      "docker"
      "networkmanager"

      # Desktop access — always needed for audio, input, and video devices
      "audio"
      "input"
      "video"
    ];
    isNormalUser = true;
    shell = pkgs.fish;
  };

  users.groups.hasundue = { };

  virtualisation.docker.enable = true;
}
