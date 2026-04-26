{
  firefox-addons,
  mcp-nixos,
  models-dev,
}:
_: prev:
let
  inherit (prev.stdenv.hostPlatform) system;
in
{
  firefox-addons = firefox-addons.packages.${system};
  mcp-nixos = mcp-nixos.packages.${system}.default;
  modelsDevSource = models-dev;
}
