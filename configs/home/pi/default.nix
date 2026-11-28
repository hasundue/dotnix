{
  config,
  lib,
  pkgs,
  ...
}:
let
  opencodeGoKey = config.age.secrets."api/opencode-go".path;
  piAuthFile = "${config.programs.pi-coding-agent.configDir}/auth.json";
  piPackage = config.programs.pi-coding-agent.package;
  piPackageRoot = pkgs.symlinkJoin {
    name = "pi-package-root";
    paths = [
      "${piPackage}/lib/node_modules/pi-monorepo"
      (pkgs.linkFarm "pi-source" [
        {
          name = "src";
          path = "${piPackage.src}/packages/coding-agent/src";
        }
      ])
    ];
  };
in
{
  imports = [ ./zotero.nix ];

  # pi itself plus the PDF toolchain, managed here.
  #
  # Policy: use the CLI wherever a binary is enough; keep pure Python only for
  # table structure and reading-order control. pdf2image and pytesseract are not
  # included: both merely shell out to the binaries below.
  programs.pi-coding-agent = {
    enable = true;

    # Keep settings.json writable: pi rewrites it (/model, changelog), so only
    # the declared keys are merged in.
    mutableSettings = true;
    settings = {
      # The package stays installed and its extension stays discovered but
      # disabled, so `pi config` lists it and `pi config -l` can switch it on
      # for a project. `autoload = false` would hide it from `pi config`
      # entirely; an empty `extensions` filter keeps the entry with
      # `enabled: false`, which the resource loader skips.
      packages = [
        {
          source = "npm:pi-gpui";
          extensions = [ ];
        }
      ];
      defaultTools = [
        "+grep"
        "+find"
        "+ls"
        "+codemode"
      ];
      # Skills that stay installed but hidden from discovery; a project opts in
      # from its .pi/settings.json:
      #   { "skills": ["~/.pi/agent/skills/pdf-tools", ...] }
      # Patterns resolve from the agent directory (~/.pi/agent).
      skills = [
        # Verifying something on screen is a per-task decision, so it is opt-in
        # instead of part of every session.
        "-skills/niri"
        # Research only: nothing needs them until a project reads papers.
        "-skills/pdf-tools"
        "-skills/zotero-pdf"
      ];
      extensions = [
        ./agent/extensions
      ];
    };

    extraPackages = [
      # CLI: rendering, text extraction, OCR, structural edits
      pkgs.poppler-utils # pdftoppm, pdftotext, pdfimages, pdfunite, pdfseparate
      pkgs.tesseract # OCR (tsv / hocr output carries word coordinates)
      pkgs.qpdf # split, merge, rotate, encrypt, overlay, structural check
      # Pure Python (no subprocesses of their own): table cells and reading order
      (pkgs.python3.withPackages (ps: [
        ps.pypdf
        # Skip pdfplumber's install check. Its nativeCheckInputs pull
        # pandas-stubs -> pyiceberg -> geoarrow-pyarrow -> geopandas, and at the
        # nixpkgs revision pinned here geopandas' tests fail: shapely is fetched
        # without git metadata, so shapely.__version__ is "0+unknown" and
        # geopandas disables its >= 2.0 code paths. The runtime closure
        # (pdfminer-six, pillow, pypdfium2) is unaffected by the tests.
        #
        # doCheck, not doInstallCheck: mk-python-derivation derives
        # doInstallCheck from doCheck, and only a set doInstallCheck splices
        # nativeInstallCheckInputs into the derivation inputs.
        (ps.pdfplumber.overridePythonAttrs (_: {
          doCheck = false;
        }))
        # Not a PDF tool: pi bundles no tokenizer for its models, and a
        # character count is only good to a guess. The BPE file is fetched on
        # first use, so point TIKTOKEN_CACHE_DIR at a real directory to keep it.
        ps.tiktoken
      ]))
    ];
  };

  # TEMPORARY: Pi resolves auth.json symlinks before locking, which makes a
  # Nix-store-backed file fail because the store is read-only. Remove this
  # workaround once upstream handles that case:
  # https://github.com/earendil-works/pi/pull/11787#issuecomment-6846777190
  home.activation.piAuth = lib.hm.dag.entryAfter [ "linkGeneration" ] (
    lib.hm.generators.mkImpureConfigMerger {
      inherit pkgs;
      format = "json";
      empty = "{}";
      mode = "600";
      path = piAuthFile;
      staticSettings = pkgs.writeText "pi-auth.json" (
        builtins.toJSON {
          "opencode-go" = {
            type = "api_key";
            key = "!${pkgs.coreutils}/bin/cat ${opencodeGoKey}";
          };
        }
      );
      # Keep credentials for other providers and runtime-managed fields, while
      # making the declared opencode-go values authoritative.
      jqOperation = "$dynamic * $static";
    }
    + ''
      if [[ ! -v DRY_RUN ]]; then
        ${lib.getExe' pkgs.coreutils "chmod"} 600 ${lib.escapeShellArg piAuthFile}
      fi
    ''
  );

  # Store-backed links are read-only: edit the repository and activate to change
  # any of these files. settings.json and auth.json stay writable (see above).
  home.file = {
    ".pi/agent/AGENTS.md".source = ./agent/AGENTS.md;
    ".pi/agent/APPEND_SYSTEM.md".source = ./agent/APPEND_SYSTEM.md;
    ".pi/agent/models.json".source = ./agent/models.json;
    ".pi/agent/mcp.json".source = ./agent/mcp.json;
    ".pi/agent/keybindings.json".source = ./agent/keybindings.json;
    ".pi/agent/prompts".source = ./agent/prompts;
    ".pi/agent/skills".source = ./agent/skills;

    # auth.json is created as a regular mutable file by home.activation.piAuth:
    # Pi's lock must be writable, and other providers' credentials may change.
  };

  # Pi resolves its own docs paths from getPackageDir(), which honours
  # PI_PACKAGE_DIR for Nix/Guix. The joined root also carries the coding-agent
  # src/, so docs links like ../src/... resolve locally.
  xdg.dataFile."pi/package".source = piPackageRoot;
  home.sessionVariables.PI_PACKAGE_DIR = "${config.xdg.dataHome}/pi/package";
}
