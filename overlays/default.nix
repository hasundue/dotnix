{ firefox-addons, ... }:

[
  (final: prev: {
    firefox-addons = firefox-addons.packages.${final.system};
  })
]
