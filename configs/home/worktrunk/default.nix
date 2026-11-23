{ lib, ... }:
let
  mkHooks = (import ../worktree-hooks { }).mkHooks;
  hooks = mkHooks {
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
      # One hook per step: Worktrunk runs keys in the same block concurrently,
      # so setup must not share a block with the copies it depends on.
      post-start = lib.mapAttrsToList (name: body: { ${name} = body; }) hooks;
    };
  };
}
