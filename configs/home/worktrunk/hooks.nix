{ ... }:
{
  # Callers supply the shell expressions for the source and destination
  # checkouts; all interpolation happens here, in Nix. The result is a partial
  # worktrunk.settings: post-start is a list of blocks, with keys in one block
  # running concurrently. Setup is a later block because it needs the copied
  # .envrc.
  mkHooks =
    { primary, worktree }:
    {
      post-start = [
        {
          copy-envrc = ''
            if test -f "${primary}/.envrc"; then
              cp "${primary}/.envrc" "${worktree}/.envrc"
            fi
          '';
          copy-pi-settings = ''
            if test -f "${primary}/.pi/settings.json" && test ! -e "${worktree}/.pi/settings.json"; then
              mkdir -p "${worktree}/.pi"
              cp "${primary}/.pi/settings.json" "${worktree}/.pi/settings.json"
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
    };
}
