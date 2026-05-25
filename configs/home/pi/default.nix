{
  config,
  pkgs,
  ...
}:
{
  programs.git.ignores = [
    ".pi/"
  ];
}
