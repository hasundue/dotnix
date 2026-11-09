{ ... }:

{
  imports = [ ./focus-dismiss.nix ];

  services.mako = {
    enable = true;
    settings = {
      border-radius = 4;
      border-size = 0;
      padding = "10,20";

      "app-name=niri" = {
        default-timeout = 3000;
      };
    };

    # niri's `app-id` → the names the app uses for its notifications.
    focusDismiss.aliases = {
      "sh.waku" = [ "Waku" ];
    };
  };
}
