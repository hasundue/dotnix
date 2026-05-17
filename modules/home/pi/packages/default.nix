# Per-package pi extension submodules.
# Each file here configures a specific npm package's options and home.file entries.
{
  imports = [
    ./pi-subagents.nix
    ./pi-mcporter.nix
    ./pi-web-providers.nix
  ];
}
