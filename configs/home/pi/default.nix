{
  config,
  pkgs,
  ...
}:
let
  live = config.dotnix.live.pi;
  opencodeGoKey = config.age.secrets."api/opencode-go".path;

  # Every entry of ./agent is served from the live directory, so editing it
  # takes effect without a rebuild. settings.json is deliberately absent: pi
  # writes it itself (`/settings`, `pi update`), and it holds values such as
  # lastChangelogVersion that Nix must not pin.
  link = path: config.lib.file.mkOutOfStoreSymlink "${live.stable}/${path}";
in
{
  # pi itself plus the PDF toolchain, managed here.
  #
  # Policy: use the CLI wherever a binary is enough; keep pure Python only for
  # table structure and reading-order control. pdf2image and pytesseract are not
  # included: both merely shell out to the binaries below.
  programs.pi-coding-agent = {
    enable = true;
    extraPackages = [
      # CLI: rendering, text extraction, OCR, structural edits
      pkgs.poppler-utils # pdftoppm, pdftotext, pdfimages, pdfunite, pdfseparate
      pkgs.tesseract # OCR (tsv / hocr output carries word coordinates)
      pkgs.qpdf # split, merge, rotate, encrypt, overlay, structural check
      # Pure Python (no subprocesses of their own): table cells and reading order
      (pkgs.python3.withPackages (ps: [
        ps.pypdf
        ps.pdfplumber
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
