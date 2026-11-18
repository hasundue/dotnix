{ pkgs, ... }:
let
  # Hook helpers: store-path binaries, deliberately not in home.packages, so
  # they stay out of the user's PATH. The generated config below embeds their
  # store paths in the hook commands, and no hook body is more than one line,
  # which keeps Worktrunk's hook echoes short.
  #
  # pi-trust-cleanup removes the removed worktree's entry from Pi's
  # trust.json when Worktrunk takes a worktree away. It lives with Worktrunk
  # rather than pi-worktrunk: only Worktrunk knows when a path stops being a
  # worktree, and the store is Pi's, so the helper is kept out of
  # pi-worktrunk's approval flow.
  pi-trust-cleanup = pkgs.writeShellApplication {
    name = "pi-trust-cleanup";
    runtimeInputs = with pkgs; [
      coreutils
      jq
    ];
    text = builtins.readFile ./pi-trust-cleanup.sh;
  };

  # rehome-live repoints dotnix.live.* links away from a worktree being
  # removed. It is a user hook, not a project hook: the project `.config/wt.toml`
  # could not reference a store path, and Worktrunk echoes a project hook's
  # body whenever it runs, so the old inline body was a wall of output. As a
  # user hook it runs in every repository, where it no-ops on the unmatched
  # links, and it needs no project approval.
  rehome-live = pkgs.writeShellApplication {
    name = "rehome-live";
    runtimeInputs = [ pkgs.coreutils ];
    text = builtins.readFile ./rehome-live.sh;
  };

  # copy-pi-settings gives a new worktree the primary checkout's
  # .pi/settings.json, which git ignores: without it pi loses the project's
  # packages (pi-worktrunk, for one). It copies only when the source exists
  # and the target does not, so a checkout that deliberately dropped its own
  # copy keeps it.
  copy-pi-settings = pkgs.writeShellApplication {
    name = "copy-pi-settings";
    runtimeInputs = [ pkgs.coreutils ];
    text = builtins.readFile ./copy-pi-settings.sh;
  };

  # The user Worktrunk config, generated so hook commands can carry store
  # paths. The {{ ... }} in hook commands are Worktrunk template variables;
  # Worktrunk shell-escapes each substituted path, so a hook may quote it.
  configTOML = ''
    skip-shell-integration-prompt = true

    [merge]
    commit = false    # --no-commit by default
  ''
  # A worktree starts from a commit, so a file git ignores is missing there.
  # Both helpers work in every repository, so neither asks a repository to
  # opt in.
  + ''
    [post-start]
    copy-envrc = "test -f {{ primary_worktree_path }}/.envrc && cp {{ primary_worktree_path }}/.envrc {{ worktree_path }}/.envrc"
    copy-pi-settings = "${copy-pi-settings}/bin/copy-pi-settings {{ primary_worktree_path }}/.pi/settings.json {{ worktree_path }}/.pi/settings.json"
  ''
  # Runs in the worktree being removed, before the directory goes away, so
  # a failure stops the removal. In repositories other than this one no
  # dotnix.live.* link points into the removed worktree and the helper
  # no-ops.
  + ''
    [pre-remove]
    rehome-live = "${rehome-live}/bin/rehome-live {{ worktree_path }} {{ primary_worktree_path }}"
  ''
  # Runs only after Worktrunk has completed the removal: the removed
  # worktree's path is known and the store is untouched when the removal is
  # cancelled or fails. The helper deletes only that worktree's key, so the
  # primary checkout and its sibling worktrees stay trusted. It fails
  # without writing when the trust store cannot be locked or parsed.
  + ''
    [post-remove]
    cleanup-pi-trust = "${pi-trust-cleanup}/bin/pi-trust-cleanup {{ worktree_path }}"
  '';
in
{
  home.packages = [ pkgs.worktrunk ];

  home.file.".config/worktrunk/config.toml".text = configTOML;

  programs.fish.interactiveShellInit = ''
    ${pkgs.worktrunk}/bin/wt config shell init fish | source
  '';
}
