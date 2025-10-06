{
  stdenv,
  lib,
  fetchFromGitHub,
  pkg-config,
  libfprint,
  gusb,
  pixman,
  glib,
  nss,
  meson,
  ninja,
  gtk-doc,
  docbook-xsl-nons,
  gobject-introspection,
}:
stdenv.mkDerivation rec {
  pname = "libfprint-2-tod1-vfs0097";
  version = "unstable-2024-01-15";

  src = fetchFromGitHub {
    owner = "3v1n0";
    repo = "libfprint";
    rev = "vfs009x/5.15.139.27";
    hash = "";
  };

  nativeBuildInputs = [
    pkg-config
    meson
    ninja
    gtk-doc
    docbook-xsl-nons
    gobject-introspection
  ];

  buildInputs = [
    glib
    gusb
    pixman
    nss
  ];

  mesonFlags = [
    "-Dudev_rules=enabled"
    "-Dudev_rules_dir=${placeholder "out"}/lib/udev/rules.d"
    "-Ddrivers=vfs0097"
    "-Dgtk_examples=false"
  ];

  passthru.driverPath = "/lib/libfprint-2/tod-1";

  meta = with lib; {
    description = "Validity vfs009x (vfs0097) driver for libfprint";
    homepage = "https://github.com/3v1n0/libfprint";
    license = licenses.lgpl21Plus;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
