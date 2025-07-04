{ pkgs, ... }:

let
  spotify = pkgs.spotify.overrideAttrs (old: {
    postFixup = ''
      # Patch the wrapper script to add --wayland-text-input-version=3
      substitute $out/share/spotify/spotify $out/share/spotify/spotify.tmp \
        --replace "--enable-wayland-ime=true" "--enable-wayland-ime --wayland-text-input-version=3"
      mv $out/share/spotify/spotify.tmp $out/share/spotify/spotify
      chmod +x $out/share/spotify/spotify
    '';
  });
in
{
  home.packages = [ spotify ];
}
