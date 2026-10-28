{ pkgs, ... }:
{
  # pi 本体 + PDF/OCR ツール一式をここで管理する。
  # 設定 (~/.pi/agent) は pi-config リポジトリ管理のままにするため、
  # settings / models / keybindings / context / appendSystem は意図的に未設定。
  # これらが空の間、home-manager は configDir 配下に一切ファイルを書かない。
  programs.pi-coding-agent = {
    enable = true;
    extraPackages = [
      # CLI: PDF -> 画像 / テキスト
      pkgs.poppler-utils # pdftoppm, pdftotext, pdfinfo
      pkgs.qpdf # 分割・結合・回転・復号
      pkgs.tesseract # OCR
      # Python ライブラリ (pi の中だけで見える)
      (pkgs.python3.withPackages (
        ps: with ps; [
          pypdf
          pdfplumber
          pdf2image
          pytesseract
          pillow
        ]
      ))
    ];
  };
}
