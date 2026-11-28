{
  config,
  lib,
  pkgs,
  ...
}:
let
  pluginId = "local.worktree-handoff";
  pluginDir = "${config.home.homeDirectory}/.config/herdr/plugins/worktree-handoff";
  bash = lib.getExe pkgs.bash;
  jq = lib.getExe pkgs.jq;
  herdr = lib.getExe pkgs.herdr;

  # The tool writes one JSON file per handoff into this plugin's state dir.
  # The action consumes jobs in filename order and keeps each job as .running
  # until agent start succeeds. Failed jobs become .failed and are not replayed.
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
      if output=$(${herdr} agent start "$agent" --kind pi --pane "$pane" --timeout 120000 -- \
        "''${extra[@]}" --herdr-worktree-handoff "$old_pane" -a --fork "$session" 2>&1); then
        rm -f "$job.running"
      else
        status=$?
        printf '%s\n' "$output" > "$job.error"
        mv "$job.running" "$job.failed"
        ${herdr} notification show "Worktree handoff failed" \
          --body "Could not start $agent in $pane: $output" || true
        ${herdr} workspace focus "''${old_pane%%:*}" || true
        printf '%s\n' "$output" >&2
        exit "$status"
      fi
    done
  '';

  manifest = ''
    id = "${pluginId}"
    name = "Worktree Handoff"
    version = "1.0.0"
    min_herdr_version = "0.9.0"
    description = "Start forked Pi sessions queued by herdr_worktree_move"
    platforms = [ "linux", "macos" ]

    [[actions]]
    id = "handoff"
    title = "Worktree handoff"
    description = "Start the forked Pi session queued by herdr_worktree_move"
    command = [ "${bash}", "${pluginDir}/handoff.sh" ]
  '';
in
{
  home.file.".config/herdr/plugins/worktree-handoff/herdr-plugin.toml".text = manifest;
  home.file.".config/herdr/plugins/worktree-handoff/handoff.sh".text = handoffScript;

  home.activation.linkHerdrWorktreeHandoff = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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
