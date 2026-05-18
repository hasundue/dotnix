# Per-package pi extension submodules.
# Each file here configures a specific npm package's options and home.file entries.
{
  imports = [
    ./pi-mcporter.nix
    ./pi-subagents.nix
    ./pi-web-providers.nix
    ./rpiv-advisor.nix
    ./rpiv-pi.nix
    ./rpiv-web-tools.nix
  ];
}
