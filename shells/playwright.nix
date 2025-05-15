{ pkgs, ... }:

pkgs.mkShellNoCC {
  nativeBuildInputs = with pkgs; [
    vscode
    playwright-driver.browsers
  ];
  shellHook = ''
    export PLAYWRIGHT_BROWSERS_PATH=${pkgs.playwright-driver.browsers}
    export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
  '';
}
