{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  formats,
  libxcb,
  libxkbcommon,
  libxi,
  libglvnd,
  vulkan-loader,
  wayland,
  ibm-plex,
  jetbrains-mono,
  # Optional package of extra faces, added to the app's fontconfig after the
  # families Waku asks for by name. Callers use it to supply whatever the
  # system does not provide in a form GPUI can render, e.g. a static CJK face.
  fallbackFont ? null,
  version ? "0.1.20",
}:

# Waku ships prebuilt GPUI binaries only; upstream has neither a flake nor a
# nixpkgs package. The release tree is installed verbatim because `waku`
# resolves `waku-daemon`, `waku-updater`, and its resources relative to its own
# executable (`current_exe()`), so the binaries have to stay siblings under
# `bin/`.
#
# Self-update is inert here without patching: `InstallLayout::discover()`
# (src/updater/linux.rs) refuses to manage any prefix that does not live under
# `$HOME`, so the app never tries to rewrite itself inside /nix/store.
let
  release = {
    x86_64-linux = {
      asset = "x86_64-unknown-linux-gnu";
      hash = "sha256-i61Wnzo3lK7a5Pef+vcR/puO8xc+YFwAnOB6caeupBU=";
    };
    aarch64-linux = {
      asset = "aarch64-unknown-linux-gnu";
      hash = "sha256-sHXj+4yoXhuo339yqkdEek+9G5m5harK2etQRq5rG7k=";
    };
  };
  platform =
    release.${stdenv.hostPlatform.system}
      or (throw "waku: unsupported system ${stdenv.hostPlatform.system}");

  # Only the Latin family: the default `ibm-plex` selection also pulls in the
  # Arabic, Thai, Devanagari and CJK variants (~340 MiB), none of which this UI
  # font needs — Japanese and friends come from the system through the include.
  plexSans = ibm-plex.override { families = [ "sans" ]; };

  # Waku never asks fontconfig which font is the system UI font. GPUI rewrites
  # `.SystemUIFont` to a hardcoded platform default ("IBM Plex Sans" on Linux,
  # gpui_linux/src/linux/platform.rs) and then walks a hardcoded list of exact
  # family names (gpui/src/text_system.rs), giving up at "DejaVu Sans" on a
  # stock NixOS; code and the embedded terminal ask for "JetBrains Mono" by
  # name (src/terminal.rs, src/md/render.rs). Shipping the two families it
  # expects and pointing only this app's fontconfig at them keeps the rest of
  # the system untouched, while everything the system provides (CJK fallback,
  # emoji) stays available through the include.
  fontconfigFile = (formats.xml { }).generate "waku-fonts.conf" {
    fontconfig = {
      include = {
        "@ignore_missing" = "yes";
        "#text" = "/etc/fonts/fonts.conf";
      };
      dir = [
        "${plexSans}/share/fonts"
        "${jetbrains-mono}/share/fonts"
      ]
      ++ lib.optional (fallbackFont != null) "${fallbackFont}/share/fonts";
    };
  };
in
stdenv.mkDerivation {
  pname = "waku";
  inherit version;

  src = fetchurl {
    url = "https://github.com/egoist/waku/releases/download/v${version}/waku-${version}-${platform.asset}.tar.gz";
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
    libxi # DT_NEEDED by the X11 computer-use driver, libcua_driver_sdk.so
    stdenv.cc.cc.lib # libgcc_s.so.1 for the Rust binaries
  ];

  # dlopen()ed libraries never appear in DT_NEEDED, so autoPatchelfHook would
  # leave them out of the RPATH without this.
  runtimeDependencies = [
    libglvnd # libEGL.so.1, used by the renderer
    wayland # libwayland-client.so.0 and libwayland-egl.so.1
    vulkan-loader # libvulkan.so.1, when a Vulkan device is selected
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out

    # The packaged entry is relocatable (bare Exec/Icon names). Pin both to the
    # store path so the launcher works without PATH or icon-theme setup, the
    # same rewrite the upstream install.sh performs.
    desktopEntry=$out/share/applications/sh.waku.desktop
    substituteInPlace $desktopEntry \
      --replace-fail "Exec=waku" "Exec=$out/bin/waku" \
      --replace-fail "Icon=sh.waku" "Icon=$out/share/icons/hicolor/256x256/apps/sh.waku.png"

    runHook postInstall
  '';

  # The wrapper renames the real binary to `.waku-wrapped`; the daemon is still
  # found because it is resolved as a sibling of /proc/self/exe, and the
  # self-update check fails on the name anyway (it is disabled by the store
  # prefix regardless). `WAKU_APP_EXECUTABLE` therefore points at the inner
  # binary, which only matters for OpenCode's synthetic-image path.
  postFixup = ''
    wrapProgram $out/bin/waku --set FONTCONFIG_FILE ${fontconfigFile}
  '';

  meta = {
    description = "Native app that drives local coding-agent CLIs in one window";
    homepage = "https://waku.sh";
    license = lib.licenses.gpl3Only;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = builtins.attrNames release;
    mainProgram = "waku";
  };
}
