{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  # nixpkgs' `patchelf` is 0.15.2, whose `--set-rpath` corrupts this Go
  # executable: the result dies on SIGSEGV at 0x4002e0 before ld.so maps
  # anything, while the same binary with only its interpreter set runs. 0.19.2,
  # from the unstable attribute, patches it and the app runs, so it is placed
  # after the hook that shells out to `patchelf` by name.
  patchelfUnstable,
  wrapGAppsHook3,
  gtk3,
  webkitgtk_4_1,
  glib,
  at-spi2-core,
  cairo,
  fontconfig,
  freetype,
  gdk-pixbuf,
  harfbuzz,
  libepoxy,
  libsoup_3,
  pango,
  wayland,
  xdg-utils,
  version ? "2.1.35",
}:

# Kero ships prebuilt binaries only; upstream has neither a flake nor a nixpkgs
# package, and the release tarball is the only artifact for Linux. The tarball
# is flat: `kero`, `libghostty-vt.so`, `fonts/`, `icon.png`, `kero.png`,
# `kero.desktop` and `.mygo-files` at its root.
#
# It is installed with the tree intact under `$out/libexec/kero` and symlinked
# from `$out/bin/kero`, matching the layout upstream's own installer produces:
# `/opt/kero/kero` plus a link in `~/.local/bin` (docs/quick-start.md).
# `mygo.App.Path(mygo.PathResources)` resolves to the *real* directory of the
# executable (`paths.go`, `resourcesDir()`), so the binary has to keep its
# siblings — fonts and the terminal library — next to it; a `$out/bin/kero`
# holding the binary itself would need them in `$out/bin` instead.
#
# The single binary is the app, the `kero` CLI and `kerod`: `kero help` and
# `kero ls` run headless, while `kero` alone opens the window.
let
  release = {
    x86_64-linux = {
      asset = "amd64";
      hash = "sha256-Wl9G6QC9ZH9CKjp5OCFXgUAwIAswruVTxSXzhLWUCMQ=";
    };
    aarch64-linux = {
      asset = "arm64";
      hash = "sha256-v0Kv0kvLXFkVZzFz4Kco67ZMJpmO2Di19Ayo7Cb8tdE=";
    };
  };
  platform =
    release.${stdenv.hostPlatform.system}
      or (throw "kero: unsupported system ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "kero";
  inherit version;

  src = fetchurl {
    url = "https://github.com/egoist/kero/releases/download/v${version}/kero-${version}-linux-${platform.asset}.tar.gz";
    inherit (platform) hash;
  };

  # Everything is prebuilt; only the ELF interpreter and RPATH need fixing.
  dontBuild = true;
  dontStrip = true;

  # The tarball's root holds files as well as the `fonts/` directory, and the
  # unpacker would otherwise mistake that single directory for the source root.
  sourceRoot = ".";

  nativeBuildInputs = [
    autoPatchelfHook
    wrapGAppsHook3
    patchelfUnstable
  ];

  # wrapGAppsHook3 wraps every executable under `$out/bin` *and* `$out/libexec`
  # (wrap-gapps-hook.sh, `targetDirs`), which here would turn the shipped
  # `libghostty-vt.so` — executable, as shared libraries are — into a wrapper
  # executable and leave the terminal without its library. Only the one program
  # is wrapped, below; the hook still fills `gappsWrapperArgs` for it, which is
  # what carries the GTK, gdk-pixbuf and GSettings paths.
  dontWrapGApps = true;

  # The .deb's Depends line (libgtk-3-0, libwebkit2gtk-4.1-0). There is no
  # link-time dependency at all: mygo reaches GTK through purego, which
  # dlopen()s these by soname as the app needs them — so nothing lands in
  # DT_NEEDED and the RPATH has to name every library by hand. The list is the
  # `lib*.so.*` strings in the binary: glib's (glib, gobject, gio), ATK, GDK and
  # GTK, cairo, gdk-pixbuf, harfbuzz, pango and pangoft2/pangocairo, fontconfig,
  # epoxy, wayland-client, soup, and WebKitGTK with JavaScriptCore. Debian
  # needs no list, because its own copies sit in /usr/lib.
  #
  # `lib.getLib` rather than the attributes themselves: glib's and pango's
  # default output is `bin`, which holds no libraries.
  runtimeDependencies = map lib.getLib [
    glib
    at-spi2-core
    cairo
    fontconfig
    freetype
    gdk-pixbuf
    gtk3
    harfbuzz
    libepoxy
    libsoup_3
    pango
    wayland
    webkitgtk_4_1
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/libexec/kero $out/bin
    cp -a . $out/libexec/kero
    ln -s $out/libexec/kero/kero $out/bin/kero

    # Upstream's icon.png and kero.png are the same 1024x1024 image; the .deb
    # installs resized copies under /usr/share/icons, which none of them need.
    install -Dm644 $out/libexec/kero/kero.png \
      $out/share/icons/hicolor/1024x1024/apps/kero.png
    install -Dm644 $out/libexec/kero/kero.desktop \
      $out/share/applications/kero.desktop

    # The packaged entry is relocatable (bare Exec/Icon names). Pin both to the
    # store so the launcher works without PATH or icon-theme setup.
    substituteInPlace $out/share/applications/kero.desktop \
      --replace-fail "Exec=kero" "Exec=$out/bin/kero" \
      --replace-fail "Icon=kero" "Icon=$out/share/icons/hicolor/1024x1024/apps/kero.png"

    runHook postInstall
  '';

  # `xdg-open` opens a file in its app and reveals one in the file manager
  # (platform.go); `gio` moves a deleted file to the trash. Neither is on a
  # NixOS desktop session's PATH, and the app shells out with the inherited PATH
  # otherwise, failing silently when they are absent.
  #
  # Wrapped in place, beside the resources `mygo.App.Path(mygo.PathResources)`
  # looks for (`resourcesDir()` uses the executable's directory), so that the
  # wrapper's target and those resources stay together.
  postFixup = ''
    wrapProgram $out/libexec/kero/kero \
      "''${gappsWrapperArgs[@]}" \
      --prefix PATH : ${
        lib.makeBinPath [
          glib
          xdg-utils
        ]
      }
  '';

  meta = {
    description = "A terminal for coding agents";
    homepage = "https://kero.sh";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = builtins.attrNames release;
    mainProgram = "kero";
  };
}
