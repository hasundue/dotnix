{
  firefox-addons,
  kanagawa-bat,
  kanagawa-delta,
  models-dev,
  rpiv-mono,
}:
_: prev:
let
  inherit (prev.stdenv.hostPlatform) system;
in
{
  firefox-addons = firefox-addons.packages.${system};
  kanagawa = {
    bat = kanagawa-bat;
    delta = kanagawa-delta;
  };
  modelsDevSource = models-dev;
  rpivMonoSrc = rpiv-mono;
}
