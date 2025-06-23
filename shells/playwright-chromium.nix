{ pkgs, ... }:

let
  playwright-browsers = pkgs.playwright-driver.browsers.override {
    withFirefox = false;
    withWebkit = false;
  };
in
pkgs.mkShell {
  shellHook = ''
    export PLAYWRIGHT_BROWSERS_PATH=${playwright-browsers}
    export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
  '';
}
