{
  imports = [
    ../../nixos
  ];

  networking.hostName = "higame";

  # WSL does not inherit the Windows host's time zone and nothing else sets it,
  # so without this the whole system stays on UTC (9 hours behind JST). The
  # laptop leaves the zone unset so `automatic-timezoned` can follow geoclue;
  # this host is stationary, so pin it instead.
  time.timeZone = "Asia/Tokyo";

  # nixos-wsl disables systemd-timesyncd because the WSL host already keeps the
  # guest clock tied to the Windows one via Hyper-V implicit time sync. Running
  # a daemon on top of that does not work: chrony reported "System clock
  # interference detected", escalated its frequency estimate to ~2 % and swung
  # the offset by ±300 ms. Leave clock accuracy to the Windows side (w32time).

  # Keep the UID this host's user was created with. nixos-wsl defaults it to
  # 1000, and home-manager derives `home.uid` from it and aborts activation when
  # it disagrees with the running user.
  users.users.hasundue.uid = 1001;

  wsl = {
    enable = true;
    defaultUser = "hasundue";
  };
}
