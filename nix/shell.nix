{ pkgs ? import <nixpkgs> { } }: with pkgs; 

mkShell {
  buildInputs = [
    deno
    nixpkgs-fmt
  ];

  shellHook = ''
    # ...
  '';
}
