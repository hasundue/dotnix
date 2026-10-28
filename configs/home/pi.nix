{ pkgs, ... }:
{
  # pi itself plus the PDF toolchain, managed here.
  # Configuration (~/.pi/agent) stays under the pi-config repository, so
  # settings / models / keybindings / context / appendSystem are left unset.
  # While they are empty, home-manager writes nothing into configDir.
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
}
