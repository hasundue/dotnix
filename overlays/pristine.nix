{
  firefox-addons,
  models-dev,
  rpiv-mono,
}:
_: prev:
let
  inherit (prev.stdenv.hostPlatform) system;
in
{
  firefox-addons = firefox-addons.packages.${system};
  modelsDevSource = models-dev;
  rpivMonoSrc = rpiv-mono;
}
