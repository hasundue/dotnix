{ lib, config, pkgs, ... }:

let
  cfg = config.programs.rpiv-sync;
  inherit (lib) mkIf mkOption types;
  inherit (lib.attrsets) mapAttrs' nameValuePair filterAttrs;
  inherit (lib.hm.dag) entryAfter;
  gitBin = "${lib.getBin pkgs.git}/bin/git";
  rsyncBin = "${lib.getBin pkgs.rsync}/bin/rsync";
  sharedRoot = cfg.rootDir;

  # Per-project store directory helper
  projectStore = pname: "${sharedRoot}/${pname}";

  # Filter to enabled projects only
  enabledProjects = filterAttrs (_: p: p.enable) cfg.projects;

  # ── Per-project migration activation scripts ────────────────────
  projectMigrateActivations = mapAttrs' (name: project:
    nameValuePair "rpivSyncMigrate-${name}" (entryAfter [ "rpivSyncBootstrap" ] ''
      GIT="${gitBin}"
      RSYNC="${rsyncBin}"
      STORE="${projectStore project.storePath}"
      PRIMARY="${project.primaryWorktreePath}"
      ROOT="${sharedRoot}"

      # Derive worktree glob: explicit if set, else "$(basename $PRIMARY)*"
      ${if project.worktreeGlob != null then ''
        GLOB="${project.worktreeGlob}"
      '' else ''
        GLOB="$(basename "$PRIMARY")*"
      ''}

      # Create store subdirectory
      mkdir -p "$STORE"

      # ── Worktree/primary migration ──
      # The loop matches both worktrees and primary for all projects.
      # For standalone repos (rpiv-mono), GLOB="rpiv-mono*" matches ~/rpiv-mono.
      HOME_DIR="${config.home.homeDirectory}"
      for w in "$HOME_DIR"/$GLOB; do
        [ -d "$w" ] || continue
        if [ -d "$w/.rpiv" ] && [ ! -L "$w/.rpiv" ]; then
          echo "rpiv-sync: migrating $w/.rpiv → $STORE"
          "$RSYNC" -a "$w/.rpiv/" "$STORE/"
          rm -rf "$w/.rpiv"
          ln -sfn "$STORE" "$w/.rpiv"
        fi
      done

      # Commit migrated content to canonical repo
      cd "$ROOT"
      "$GIT" add -A
      if ! "$GIT" diff --cached --quiet 2>/dev/null; then
        "$GIT" commit -m "Migrate ${name} .rpiv/ content"
      fi
    '')
  ) enabledProjects;

  # ── Per-project systemd timer+service units ──────────────────────
  # Timer-based (every 5 min) instead of inotify path units because editors
  # that use atomic-save (rename + new file) can slip past PathChanged.
  # Polling is reliable enough for artifact syncing.
  projectTimerUnits = mapAttrs' (name: project:
    nameValuePair "rpiv-sync-auto-commit-${name}" {
      Unit = {
        Description = "Periodic auto-commit for ${name} .rpiv/ store";
      };
      Timer = {
        OnCalendar = "*:0/5";
        Persistent = true;
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    }
  ) enabledProjects;

  projectServiceUnits = mapAttrs' (name: project:
    let storeDir = projectStore project.storePath; in
    nameValuePair "rpiv-sync-auto-commit-${name}" {
      Unit = {
        Description = "Auto-commit ${name} .rpiv/ store changes to canonical repo";
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "rpiv-sync-commit-${name}" ''
          set -eu
          ROOT="${sharedRoot}"
          "${gitBin}" -C "$ROOT" add -A
          if ! "${gitBin}" -C "$ROOT" diff --cached --quiet 2>/dev/null; then
            "${gitBin}" -C "$ROOT" commit -m "Auto-sync ${name} .rpiv/"
          fi
        ''}";
      };
    }
  ) enabledProjects;

in {
  options.programs.rpiv-sync = {
    enable = lib.mkEnableOption "rpiv-sync canonical .rpiv/ repo";

    rootDir = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.local/share/rpiv";
      defaultText = lib.literalExpression ''"${config.home.homeDirectory}/.local/share/rpiv"'';
      description = "Root directory for the shared canonical .rpiv/ git repo";
    };

    remote = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "git@github.com:hasundue/rpiv.git";
      description = "Remote URL for the canonical repo. Auto-added on bootstrap.";
    };

    projects = mkOption {
      type = types.attrsOf (types.submodule ({ name, ... }: {
        options = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Enable rpiv-sync for this project";
          };

          storePath = mkOption {
            type = types.str;
            default = name;
            defaultText = lib.literalExpression ''project attr name'';
            description = ''
              Subdirectory under rootDir for this project's .rpiv/ content.
              e.g. "dotnix" → ~/.local/share/rpiv/dotnix/. Defaults to the
              project attribute name.
            '';
          };

          worktreeGlob = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              Glob pattern to find worktree directories (e.g., "dotnix*").
              Defaults to null. When null, the activation script derives it
              as "$(basename ''${primaryWorktreePath})*". Set to null for
              standalone repos (no worktrees).
            '';
          };

          primaryWorktreePath = mkOption {
            type = types.str;
            description = ''
              Path to the project's primary worktree or repo directory
              (e.g., ~/dotnix). Used for initial bootstrap content.
            '';
          };

          watchDirs = mkOption {
            type = types.listOf types.str;
            default = [ "artifacts" "guidance" ];
            description = ''
              Subdirectories within the project store to watch for
              auto-commit (relative to the store path).
            '';
          };
        };
      }));
      default = { };
      description = "Projects with .rpiv/ content to sync";
    };
  };

  config = mkIf cfg.enable {
    # Ensure .rpiv/ is git-ignored (belt-and-suspenders alongside entries in
    # configs/home/pi/default.nix)
    programs.git.ignores = [ ".rpiv" ];

    # ── Per-project migration (generated via mapAttrs') ────────────
    home.activation =
      { rpivSyncBootstrap = entryAfter [ "writeBoundary" ] ''
        GIT="${gitBin}"
        ROOT="${sharedRoot}"
        mkdir -p "$ROOT"
        cd "$ROOT"

        # Init git repo if needed (idempotent)
        if ! "$GIT" rev-parse --git-dir >/dev/null 2>&1; then
          "$GIT" init
        fi
        "$GIT" config user.name "Shun Ueda"
        "$GIT" config user.email "hasundue@gmail.com"

        # Install/update post-commit hook
        mkdir -p "$ROOT/.git/hooks"
        cat > "$ROOT/.git/hooks/post-commit" << 'HOOK'
    #!/bin/sh
    # Auto-push rpiv repo after every commit.
    # Fails silently when offline or no remote configured.
    git push origin main 2>/dev/null || true
HOOK
        chmod +x "$ROOT/.git/hooks/post-commit"

        # Add remote if configured
        ${lib.optionalString (cfg.remote != null) ''
          if ! "$GIT" remote get-url origin >/dev/null 2>&1; then
            "$GIT" remote add origin "${cfg.remote}"
          fi
        ''}
      ''; }
      // projectMigrateActivations;

    # ── Per-project systemd auto-commit units ──────────────────────
    systemd.user.timers = projectTimerUnits;
    systemd.user.services = projectServiceUnits;
  };
}
