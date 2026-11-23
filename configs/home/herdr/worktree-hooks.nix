{
  config,
  lib,
  pkgs,
  ...
}:
let
  mkHooks = (import ../worktree-hooks { }).mkHooks;
  hooks = mkHooks {
    primary = "$WT_PRIMARY";
    worktree = "$WT_WORKTREE";
  };
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

    ${hooks."copy-envrc"}

    ${hooks."copy-pi-settings"}

    ${hooks.setup}
  '';

  manifest = ''
    id = "${pluginId}"
    name = "Worktree Hooks"
    version = "1.0.0"
    min_herdr_version = "0.9.0"
    description = "Shared worktree bootstrap hooks generated from Home Manager"
    platforms = [ "linux" "macos" ]

    [[events]]
    on = "worktree.created"
    command = [ "${bash}" "${pluginDir}/hooks.sh" ]
  '';
in
{
  home.file.".config/herdr/plugins/worktree-hooks/herdr-plugin.toml".text = manifest;
  home.file.".config/herdr/plugins/worktree-hooks/hooks.sh".text = script;

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
