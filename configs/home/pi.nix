{ pkgs, ... }:
{
  # pi 本体 + PDF ツール一式をここで管理する。
  # 設定 (~/.pi/agent) は pi-config リポジトリ管理のままにするため、
  # settings / models / keybindings / context / appendSystem は意図的に未設定。
  # これらが空の間、home-manager は configDir 配下に一切ファイルを書かない。
  #
  # 方針: バイナリで足りるものは CLI、表の構造化と読み順だけ純 Python。
  # pdf2image / pytesseract は同梱しない (どちらも下のバイナリを呼ぶだけのラッパー)。
  programs.pi-coding-agent = {
    enable = true;
    extraPackages = [
      # CLI: 描画・抽出・OCR・構造操作
      pkgs.poppler-utils # pdftoppm, pdftotext, pdfimages, pdfunite, pdfseparate
      pkgs.tesseract # OCR (tsv / hocr で座標も取れる)
      pkgs.qpdf # 分割・結合・回転・暗号化・overlay・検査
      # 純 Python (自前でサブプロセスを叩かない): 表のセル化と読み順の制御
      (pkgs.python3.withPackages (ps: [
        ps.pypdf
        ps.pdfplumber
      ]))
    ];
  };
}
