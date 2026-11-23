{ ... }:
let
  mkHooks = (import ../worktree-hooks { }).mkHooks;
in
{
  programs.worktrunk = {
    enable = true;
    settings = {
      "skip-shell-integration-prompt" = true;
      merge.commit = false; # --no-commit by default
      post-start = mkHooks {
        primary = "{{ primary_worktree_path }}";
        worktree = "{{ worktree_path }}";
      };
    };
  };
}
