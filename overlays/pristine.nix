{
  firefox-addons,
  models-dev,
}:
_: prev:
let
  inherit (prev.stdenv.hostPlatform) system;
in
{
  firefox-addons = firefox-addons.packages.${system};
  modelsDevSource = models-dev;
}
