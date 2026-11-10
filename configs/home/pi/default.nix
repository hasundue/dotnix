{
  config,
  pkgs,
  ...
}:
let
  live = config.dotnix.live.pi;
  opencodeGoKey = config.age.secrets."api/opencode-go".path;

  # mcp.json stays writable so pi's `/mcp` changes land in the repository;
  # settings.json is left to pi and merged through mutableSettings.
  link = path: config.lib.file.mkOutOfStoreSymlink "${live.stable}/${path}";
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
      # `/wt` passthrough with linked-session worktree moves.
      packages = [
        "npm:pi-worktrunk"
      ];
      defaultTools = [
        "+grep"
        "+find"
        "+ls"
      ];
      # PDF and Zotero skills are for research only. They stay installed but
      # hidden from discovery; a project opts in from its .pi/settings.json:
      #   { "skills": ["~/.pi/agent/skills/pdf-tools", ...] }
      # Patterns resolve from the agent directory (~/.pi/agent).
      skills = [
        "-skills/pdf-tools"
        "-skills/zotero-pdf"
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
      ]))
    ];
  };

  dotnix.live.pi = {
    enable = true;
    path = "configs/home/pi/agent";
  };

  home.file = {
    # Stable path: the checkout when live, the store copy otherwise. Consumers
    # below only ever see ~/dotnix.live.pi, never the checkout location.
    "dotnix.live.pi".source =
      if live.enable then config.lib.file.mkOutOfStoreSymlink "${live.root}/${live.path}" else ./agent;

    ".pi/agent/AGENTS.md".source = link "AGENTS.md";
    ".pi/agent/APPEND_SYSTEM.md".source = link "APPEND_SYSTEM.md";
    ".pi/agent/models.json".source = link "models.json";
    ".pi/agent/mcp.json".source = link "mcp.json";
    ".pi/agent/prompts".source = link "prompts";
    ".pi/agent/extensions".source = link "extensions";
    ".pi/agent/skills".source = link "skills";

    # A key prefixed with `!` makes pi run the command when the provider is
    # first used, so the plaintext key never reaches disk. The generated file
    # is read-only in the store: drop this declaration before `/login`-ing a
    # different provider, or switch to an activation-time merge if those
    # credentials must coexist with the managed one.
    ".pi/agent/auth.json" = {
      force = true;
      text = builtins.toJSON {
        "opencode-go" = {
          type = "api_key";
          key = "!${pkgs.coreutils}/bin/cat ${opencodeGoKey}";
        };
      };
    };
  };
}
