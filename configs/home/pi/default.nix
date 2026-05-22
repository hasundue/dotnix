{
  config,
  pkgs,
  ...
}:

let
  opencodeGoKeyPath = config.age.secrets."api/opencode-go".path;

  # Rebuild node_modules for fork wrapping derivation (Nix cache hit — same inputs)
  npmModules = pkgs.importNpmLock.buildNodeModules {
    npmRoot = ./.;
    nodejs = pkgs.nodejs;
  };

  # Fork wrapping derivation: copies the hasundue/rpiv-mono rpiv-pi source and
  # symlinks shared node_modules so @juicesharp/rpiv-config resolves at runtime.
  #
  # extensions/ is copied (not symlinked) because Node.js ESM import.meta.url
  # resolves through the symlink to the immutable source store path, which
  # doesn't have node_modules/. Copying ensures import resolution walks up from
  # the fork store path and finds the symlinked node_modules/.
  rpivPiFork = pkgs.runCommand "rpiv-pi-fork" { } ''
    set -e
    mkdir -p "$out"
    for f in ${pkgs.rpivMonoSrc}/packages/rpiv-pi/*; do
      base=$(basename "$f")
      [ "$base" = "node_modules" ] && continue
      [ "$base" = "extensions" ] && continue
      ln -s "$f" "$out/$base"
    done
    # Copy extensions/ so import.meta.url resolves to the fork store path
    cp -r --no-preserve=mode ${pkgs.rpivMonoSrc}/packages/rpiv-pi/extensions "$out/extensions"
    chmod -R u+w "$out/extensions"
    ln -s ${npmModules}/node_modules "$out/node_modules"
  '';

  # Per-agent model/thinking config consumed by the fork's feat-per-agent-model:
  # https://github.com/hasundue/rpiv-mono/blob/main/packages/rpiv-pi/extensions/rpiv-core/agents.ts
  agentModels = {
    # ── Tier A: Mechanical lookups
    codebase-locator = {
      model = "opencode-go/deepseek-v4-flash";
      thinking = "off";
    };
    codebase-pattern-finder = {
      model = "opencode-go/deepseek-v4-flash";
      thinking = "off";
    };
    integration-scanner = {
      model = "opencode-go/deepseek-v4-flash";
      thinking = "off";
    };
    diff-auditor = {
      model = "opencode-go/deepseek-v4-flash";
      thinking = "off";
    };
    peer-comparator = {
      model = "opencode-go/deepseek-v4-flash";
      thinking = "off";
    };
    test-case-locator = {
      model = "opencode-go/deepseek-v4-flash";
      thinking = "off";
    };
    artifacts-locator = {
      model = "opencode-go/deepseek-v4-flash";
      thinking = "off";
    };

    # ── Tier B: Analysis & synthesis
    codebase-analyzer = {
      model = "opencode-go/deepseek-v4-flash";
      thinking = "high";
    };
    scope-tracer = {
      # minimax is outstandingly efficient
      model = "opencode-go/minimax-m2.7";
      thinking = "off";
    };
    artifacts-analyzer = {
      model = "opencode-go/deepseek-v4-flash";
      thinking = "high";
    };
    precedent-locator = {
      # minimax is outstandingly efficient
      model = "opencode-go/minimax-m2.7";
      thinking = "off";
    };

    # ── Tier C: Adversarial gatekeeping
    claim-verifier = {
      # flash fits perfectly here.
      # Even `off` works as well but `high` for format compliance.
      model = "opencode-go/deepseek-v4-flash";
      thinking = "high";
    };
    artifact-reviewer = {
      # flash is too thorough
      model = "opencode-go/minimax-m2.7";
      thinking = "high";
    };
    slice-verifier = {
      # flash is too thorough.
      # minimax doesn't understand slice transitivity.
      model = "opencode-go/kimi-k2.5";
      thinking = "high";
    };

    # ── Tier D: Web research
    web-search-researcher = {
      model = "opencode-go/deepseek-v4-flash";
      thinking = "off";
    };
  };
in
{
  pi = {
    enable = true;
    packagesDir = ./.;

    packages = {
      pi-mcporter.settings = {
        mode = "lazy";
        timeoutMs = 30000;
      };
    };

    # Inject the fork wrapper into the pi packages array
    extraPackages = [ "${rpivPiFork}" ];

    settings = {
      theme = "kanagawa-wave";
      defaultProvider = "opencode-go";
      defaultModel = "deepseek-v4-flash";
      defaultThinkingLevel = "high";
      hideThinkingBlock = true;
      enabledModels = [
        "opencode-go/deepseek-v4-flash"
        "opencode-go/deepseek-v4-pro"
        "opencode-go/kimi-k2.6"
        "opencode-go/minimax-m2.7"
      ];
    };

    auth = {
      opencode-go = {
        type = "api_key";
        key = "!cat ${opencodeGoKeyPath}";
      };
    };

    themes = [
      ./themes/kanagawa-wave.json
    ];

    extensions = [
      ./extensions/chat-display.ts
      ./extensions/footer.ts
      ./extensions/temperature.ts
      # ./extensions/readonly-mode
      # ./extensions/toggle-bash
    ];

    skills = [
      "${pkgs.worktrunk.src}/skills/worktrunk"
      # ./skills/exa-search
      ./skills/create-deno-skill
    ];

    keybindings = {
      "app.session.rename" = "ctrl+shift+r";
    };

    context = ''
      When the user types /skill:<name> [args], pi expands it into an XML block:

      ```
      <skill name="<name>" location="/.../.../SKILL.md">
      [system guidance from pi]

      [instructions in SKILL.md]
      </skill>

      [args] (optional)
      ```

      - You have already read the skill content. DO NOT call read on the skill file.
      - Follow the instructions immediately.
      - Respond as if the user had typed `/skill:<name> [args]`.
    '';
  };

  # Agent model config for the fork's rpiv-pi.
  # Consumed at session_start by syncBundledAgents → injectFrontmatterFields.
  home.file.".config/rpiv-pi/agent-models.json" = {
    text = builtins.toJSON agentModels;
  };

  programs.git.ignores = [
    ".pi/"
    ".rpiv"
  ];

}
