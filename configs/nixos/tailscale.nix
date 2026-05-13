{
  services.tailscale = {
    enable = true;
    extraSetFlags = [ "--accept-dns=false" ]; # avoid website blocking from Tailscale DNS
    # XXX: currently "phantom" — config is applied but doesn't appear in
    # `tailscale serve status` due to set-config serving HTTP not HTTPS.
    # Workaround: sudo tailscale serve --bg --https 24096 http://localhost:4096
    # Tracked at: https://github.com/hasundue/dotnix/issues/5
    serve = {
      enable = true;
      services.opencode.endpoints."tcp:24096" = "http://localhost:4096";
    };
  };
}
