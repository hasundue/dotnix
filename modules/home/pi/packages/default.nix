# Per-package pi extension submodules.
# Each file here configures a specific npm package's options and home.file entries.
{
  imports = [
    ./pi-agents.nix
    ./pi-mcporter.nix
    ./pi-web-providers.nix
  ];
}
