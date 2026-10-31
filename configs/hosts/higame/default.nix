{
  imports = [
    ../../nixos
  ];

  networking.hostName = "higame";

  # Keep the UID this host's user was created with. nixos-wsl defaults it to
  # 1000, and home-manager derives `home.uid` from it and aborts activation when
  # it disagrees with the running user.
  users.users.hasundue.uid = 1001;

  wsl = {
    enable = true;
    defaultUser = "hasundue";
  };
}
