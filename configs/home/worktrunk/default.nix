{ ... }:
let
  # A worktree starts from a commit, so a file git ignores is missing there.
  # Both copy steps work in every repository, so neither asks a repository to
  # opt in. The second block runs after the copies: direnv needs .envrc, and
  # git hooks need the config. The {{ ... }} are Worktrunk template variables;
  # Worktrunk shell-escapes each substituted path.
  post-start = [
    {
      copy-envrc = ''
        if test -f "{{ primary_worktree_path }}/.envrc"; then
          cp "{{ primary_worktree_path }}/.envrc" "{{ worktree_path }}/.envrc"
        fi
      '';
      copy-pi-settings = ''
        if test -f "{{ primary_worktree_path }}/.pi/settings.json" && test ! -e "{{ worktree_path }}/.pi/settings.json"; then
          mkdir -p "{{ worktree_path }}/.pi"
          cp "{{ primary_worktree_path }}/.pi/settings.json" "{{ worktree_path }}/.pi/settings.json"
        fi
      '';
    }
    {
      setup = ''
        if test -f .envrc; then
          direnv allow
        fi
        if test -f flake.nix; then
          config=$(nix eval --raw .#pre-commit-config 2>/dev/null || true)
          if test -n "$config"; then
            nix build --no-link .#pre-commit-config
            ln -sfn "$config" .pre-commit-config.yaml
          fi
        fi
      '';
    }
  ];
in
{
  programs.worktrunk = {
    enable = true;
    settings = {
      "skip-shell-integration-prompt" = true;
      merge.commit = false; # --no-commit by default
      inherit post-start;
    };
  };
}
