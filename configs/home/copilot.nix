{ pkgs, ... }:
let
  github-copilot-cli = pkgs.withRuntimeDeps pkgs.github-copilot-cli (
    with pkgs;
    [
      bash
      lsof
      python3
    ]
  );
in
{
  home.packages = [ github-copilot-cli ];
}
