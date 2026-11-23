{ ... }:
let
  mkHooks = (import ./hooks.nix { }).mkHooks;
  hookSettings = mkHooks {
    primary = "{{ primary_worktree_path }}";
    worktree = "{{ worktree_path }}";
  };
in
{
  programs.worktrunk = {
    enable = true;
    settings = {
      "skip-shell-integration-prompt" = true;
      merge.commit = false; # --no-commit by default
    }
    // hookSettings;
  };
}
