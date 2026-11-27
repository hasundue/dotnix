{
  config,
  lib,
  pkgs,
  ...
}:
let
  mkHooks = (import ../worktrunk/hooks.nix { }).mkHooks;
  hookBlocks =
    (mkHooks {
      primary = "$WT_PRIMARY";
      worktree = "$WT_WORKTREE";
    }).post-start;
  # Flatten Worktrunk's blocks into one ordered script for the plugin.
  hooks = lib.concatMap (block: lib.attrValues block) hookBlocks;
  pluginId = "local.worktree-hooks";
  pluginDir = "${config.home.homeDirectory}/.config/herdr/plugins/worktree-hooks";
  bash = lib.getExe pkgs.bash;
  jq = lib.getExe pkgs.jq;
  herdr = lib.getExe pkgs.herdr;

  # The manifest points at a stable path inside the plugin root, so changing
  # a hook body only replaces hooks.sh and needs no relink.
  script = ''
    set -euo pipefail

    payload=''${HERDR_PLUGIN_EVENT_JSON:?HERDR_PLUGIN_EVENT_JSON is required}

    WT_WORKTREE=$(${jq} -er '.data.worktree.path' <<<"$payload")
    WT_PRIMARY=$(${jq} -er '.data.workspace.worktree.repo_root // .data.worktree.path' <<<"$payload")
    export WT_WORKTREE WT_PRIMARY
    cd "$WT_WORKTREE"

    ${lib.concatStringsSep "\n\n" hooks}
  '';

  # The tool writes one JSON file per handoff into the plugin state dir.
  # The action consumes jobs in filename order and removes each one before
  # starting the forked session, so a delayed invoke cannot replay a move.
  handoffScript = ''
    set -euo pipefail

    state_dir=''${HERDR_PLUGIN_STATE_DIR:?HERDR_PLUGIN_STATE_DIR is required}
    shopt -s nullglob
    for job in "$state_dir"/handoff-*.json; do
      mv "$job" "$job.running" || continue
      agent=$(${jq} -er '.agent' "$job.running")
      pane=$(${jq} -er '.pane' "$job.running")
      session=$(${jq} -er '.session' "$job.running")
      old_pane=$(${jq} -er '.oldPane' "$job.running")
      readarray -t extra < <(${jq} -r '.extraArgs // [] | .[]' "$job.running")
      rm -f "$job.running"
      ${herdr} agent start "$agent" --kind pi --pane "$pane" --timeout 120000 -- \
        "''${extra[@]}" --herdr-worktree-handoff "$old_pane" -a --fork "$session" || true
      ${herdr} agent focus "$agent" || true
    done
  '';

  manifest = ''
    id = "${pluginId}"
    name = "Worktree Hooks"
    version = "1.0.0"
    min_herdr_version = "0.9.0"
    description = "Shared worktree bootstrap hooks generated from Home Manager"
    platforms = [ "linux", "macos" ]

    [[actions]]
    id = "handoff"
    title = "Worktree handoff"
    description = "Start the forked Pi session queued by herdr_worktree_move"
    command = [ "${bash}", "${pluginDir}/handoff.sh" ]

    [[events]]
    on = "worktree.created"
    command = [ "${bash}", "${pluginDir}/hooks.sh" ]
  '';
in
{
  home.file.".config/herdr/plugins/worktree-hooks/herdr-plugin.toml".text = manifest;
  home.file.".config/herdr/plugins/worktree-hooks/hooks.sh".text = script;
  home.file.".config/herdr/plugins/worktree-hooks/handoff.sh".text = handoffScript;

  home.activation.linkHerdrWorktreeHooks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [[ -v DRY_RUN ]]; then
      $DRY_RUN_CMD ${herdr} plugin link ${lib.escapeShellArg pluginDir}
    else
      plugins=$(${herdr} plugin list --json)
      if ! ${jq} -e --arg id "${pluginId}" --arg dir ${lib.escapeShellArg pluginDir} \
        '.result.plugins | any(.plugin_id == $id and .plugin_root == $dir)' <<<"$plugins" >/dev/null; then
        ${herdr} plugin unlink ${lib.escapeShellArg pluginId} >/dev/null 2>&1 || true
        ${herdr} plugin link ${lib.escapeShellArg pluginDir} >/dev/null
      fi
    fi
  '';
}
