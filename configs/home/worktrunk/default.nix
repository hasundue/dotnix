{ ... }:
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
      # Worktrunk runs blocks in order, and keys inside one block concurrently.
      post-start = [
        hooks.copy
        { setup = hooks.setup; }
      ];
    };
  };
}
