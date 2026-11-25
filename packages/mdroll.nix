{
  lib,
  rustPlatform,
  mdrollSrc,
}:

let
  cargoManifest = builtins.fromTOML (builtins.readFile "${mdrollSrc}/Cargo.toml");
in
rustPlatform.buildRustPackage {
  pname = "mdroll";
  version = cargoManifest.package.version;

  src = mdrollSrc;

  # `nix flake update mdroll` refreshes the source hash in flake.lock and the
  # version above follows Cargo.toml. If Cargo.lock changes too, rebuild and
  # copy the `got: sha256-...` value from the -vendor hash mismatch here.
  cargoHash = "sha256-rgGOsyIIhtij4FTyPVb4W3XnOK0J/YigcnDus3zVZYk=";

  meta = {
    description = "A terminal Markdown viewer with big headings and real GFM support";
    homepage = "https://github.com/tokuhirom/mdroll";
    license = lib.licenses.mit;
    mainProgram = "mdroll";
  };
}
