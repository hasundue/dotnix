{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  formats,
  libxcb,
  libxkbcommon,
  glib,
  libglvnd,
  vulkan-loader,
  wayland,
  ibm-plex,
  # Optional package of extra faces, added to the app's fontconfig after the
  # families it asks for by name. Callers use it to supply whatever the system
  # does not provide in a form GPUI can render, e.g. the static CJK faces
  # matching each weight the UI requests.
  fallbackFont ? null,
  version ? "0.2.5",
}:

# Pi GPUI ships prebuilt GPUI binaries only; upstream has neither a flake nor a
# nixpkgs package, and the release tarball is the only artifact for Linux. The
# tree is `pi-gpui.app/` holding `bin/pi-gpui` and `share/`.
#
# It is installed flattened into `$out` instead of keeping `pi-gpui.app/`:
# `AutoUpdater::running_bundle()` (src/updater.rs) only treats the app as an
# installed copy, and therefore only updates it, when the executable sits in a
# `bin/` whose parent ends in `.app`. `$out/bin` fails that check, so the
# self-updater stays inert inside the store, as it has to be. Bundled plugins
# are unaffected: `plugin_directories()` looks for
# `<executable>/../../share/pi-gpui/plugins`, which is exactly `$out/share`.
let
  release = {
    x86_64-linux = {
      asset = "x86_64";
      hash = "sha256-dQWJTbNJld3hm70K2NAk8imnCyYgVvpp8/5BtAqyQmE=";
    };
    aarch64-linux = {
      asset = "aarch64";
      hash = "sha256-8t2mak3w/CFMus4sqAYxoUAYfbFmMxqTzFaeY0Ewass=";
    };
  };
  platform =
    release.${stdenv.hostPlatform.system}
      or (throw "pi-gpui: unsupported system ${stdenv.hostPlatform.system}");

  # Only the Latin family: the default `ibm-plex` selection also pulls in the
  # Arabic, Thai, Devanagari and CJK variants (~340 MiB), none of which this UI
  # font needs — Japanese and friends come from the system through the include.
  plexSans = ibm-plex.override { families = [ "sans" ]; };

  # GPUI never asks fontconfig which font is the system UI font. It rewrites
  # `.SystemUIFont` to a hardcoded platform default ("IBM Plex Sans" on Linux,
  # gpui/src/platform/linux/text_system.rs) and then walks a hardcoded list of
  # exact family names (gpui/src/text_system.rs), giving up at "DejaVu Sans" on
  # a stock NixOS. Code and tool output ask for "JetBrains Mono NL", which the
  # binary embeds (src/settings.rs), so only the UI family has to be shipped.
  # Pointing only this app's fontdb at it keeps the rest of the system
  # untouched, while everything the system provides (CJK fallback, emoji) stays
  # available through the include.
  fontconfigFile = (formats.xml { }).generate "pi-gpui-fonts.conf" {
    fontconfig = {
      include = {
        "@ignore_missing" = "yes";
        "#text" = "/etc/fonts/fonts.conf";
      };
      dir = [
        "${plexSans}/share/fonts"
      ]
      ++ lib.optional (fallbackFont != null) "${fallbackFont}/share/fonts";
    };
  };
in
stdenv.mkDerivation {
  pname = "pi-gpui";
  inherit version;

  src = fetchurl {
    url = "https://github.com/bytesbay/pi-gpui/releases/download/v${version}/pi-gpui-${version}-linux-${platform.asset}.tar.gz";
    inherit (platform) hash;
  };

  # Everything is prebuilt; only the ELF interpreter and RPATH need fixing.
  dontBuild = true;
  dontStrip = true;

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    libxcb # DT_NEEDED for the X11 backend
    libxkbcommon # ditto, including libxkbcommon-x11
    stdenv.cc.cc.lib # libgcc_s.so.1 for the Rust binary
  ];

  # dlopen()ed libraries never appear in DT_NEEDED, so autoPatchelfHook would
  # leave them out of the RPATH without this.
  runtimeDependencies = [
    libglvnd # libEGL.so.1, used by the renderer
    wayland # libwayland-client.so.0 and libwayland-egl.so.1
    vulkan-loader # libvulkan.so.1, the renderer's backend
  ];

  installPhase = ''
    runHook preInstall

    # The tarball's source root is `pi-gpui.app`; flatten it (see the comment
    # above this expression).
    mkdir -p $out
    cp -r . $out

    # The packaged entry is relocatable (bare Exec/Icon names). Pin both to the
    # store path so the launcher works without PATH or icon-theme setup, the
    # same rewrite upstream's install.sh performs.
    desktopEntry=$out/share/applications/pi-gpui.desktop
    substituteInPlace $desktopEntry \
      --replace-fail "Exec=pi-gpui" "Exec=$out/bin/pi-gpui" \
      --replace-fail "Icon=pi-gpui" "Icon=$out/share/icons/hicolor/512x512/apps/pi-gpui.png"

    runHook postInstall
  '';

  # `gio` trashes a deleted session and `gdbus` asks the file manager to reveal
  # a path; neither is on a NixOS desktop session's PATH, and without them the
  # app silently deletes nothing and falls back to opening the folder. It shells
  # out with the inherited PATH otherwise, so only those two are added.
  #
  # cosmic-text picks its CJK fallback family from sys_locale, which checks
  # LANGUAGE before LC_ALL/LC_MESSAGES/LANG. The value has to be exactly "ja",
  # not "ja-JP": cosmic-text matches the locale string verbatim and otherwise
  # falls through to Noto Sans CJK SC. Pi GPUI has no UI translation, so this
  # only changes which CJK faces the fallback reaches for.
  postFixup = ''
    wrapProgram $out/bin/pi-gpui \
      --set FONTCONFIG_FILE ${fontconfigFile} \
      --set LANGUAGE ja \
      --prefix PATH : ${lib.makeBinPath [ glib ]}
  '';

  meta = {
    description = "Native GUI for the pi coding agent";
    homepage = "https://pi-gpui.dev";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = builtins.attrNames release;
    mainProgram = "pi-gpui";
  };
}
