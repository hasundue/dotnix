{
  firefox-addons,
  mcp-nixos,
}:
_: prev:
let
  inherit (prev.stdenv.hostPlatform) system;
in
{
  firefox-addons = firefox-addons.packages.${system};
  mcp-nixos = mcp-nixos.packages.${system}.default;
}
