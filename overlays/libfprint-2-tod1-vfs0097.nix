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
}:
stdenv.mkDerivation rec {
  pname = "libfprint-2-tod1-vfs0097";
  version = "unstable-2024-01-15";

  src = fetchFromGitHub {
    owner = "3v1n0";
    repo = "libfprint";
    rev = "vfs009x/5.15.139.27";
    sha256 = lib.fakeSha256;
  };

  nativeBuildInputs = [
    pkg-config
    meson
    ninja
  ];

  buildInputs = [
    libfprint
    glib
    gusb
    pixman
    nss
  ];

  mesonFlags = [
    "-Dudev_rules=enabled"
    "-Ddrivers=vfs0097"
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
