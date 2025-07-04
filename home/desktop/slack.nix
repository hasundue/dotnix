{ pkgs, ... }:

let
  slack = pkgs.slack.overrideAttrs (old: {
    postInstall = ''
      # Patch the wrapper script to add --wayland-text-input-version=3
      substitute $out/bin/slack $out/bin/slack.tmp \
        --replace "--enable-wayland-ime=true" "--enable-wayland-ime --wayland-text-input-version=3"
      mv $out/bin/slack.tmp $out/bin/slack
      chmod +x $out/bin/slack
    '';
  });
in
{
  home.packages = [ slack ];
}
