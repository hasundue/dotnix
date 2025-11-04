let
  pkgs = import <nixpkgs> {
    overlays = import <nixpkgs-overlays>;
  };
  neovim = pkgs.nvim.dev.extend (
    with pkgs.nvim.exts;
    [
      nix
      python
    ]
  );
in
pkgs.mkShell {
  packages = with pkgs; [
    neovim
    pre-commit
    pythonManylinuxPackages.manylinux2014
    uv
  ];
  shellHook = ''
    if [ -d ".venv" ]; then
      source .venv/bin/activate
    fi
  '';
}
