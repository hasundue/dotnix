{ pkgs, ... }:
let
  # Removes the removed worktree's entry from Pi's trust.json when Worktrunk
  # takes a worktree away. It lives with Worktrunk rather than pi-worktrunk:
  # only Worktrunk knows when a path stops being a worktree, and the store is
  # Pi's, so the helper is kept out of pi-worktrunk's approval flow.
  pi-trust-cleanup = pkgs.writeShellApplication {
    name = "pi-trust-cleanup";
    runtimeInputs = with pkgs; [
      coreutils
      jq
    ];
    text = builtins.readFile ./pi-trust-cleanup.sh;
  };
in
{
  home.packages = [
    pkgs.worktrunk
    pi-trust-cleanup
  ];

  home.file.".config/worktrunk/config.toml".source = ./config.toml;

  programs.fish.interactiveShellInit = ''
    ${pkgs.worktrunk}/bin/wt config shell init fish | source
  '';
}
