{ pkgs, ... }:

pkgs.mkShellNoCC {
  packages = with pkgs; [
    uv
    pythonManylinuxPackages.manylinux2014
  ];
  shellHook = ''
    if [ -d ".venv" ]; then
      source .venv/bin/activate
    fi
  '';
}
