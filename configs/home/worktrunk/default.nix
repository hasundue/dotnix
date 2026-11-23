{ lib, ... }:
let
  hooks = import ../worktree-hooks { inherit lib; };
in
{
  programs.worktrunk = {
    enable = true;
    settings = {
      "skip-shell-integration-prompt" = true;
      merge.commit = false; # --no-commit by default
      post-start = hooks.worktrunk;
    };
  };
}
