{ lib, ... }:

{
  programs.opencode = {
    enable = true;

    rules = ''
      ## Response Formatting
      - Use fenced code blocks for all multi-line code/output (e.g. ``` ... ```).
      - Always include a language tag when possible (e.g., ```ts, ```sh, ```json, ```diff).
    '';

    settings = {
      model = "anthropic/claude-sonnet-4-5";
      theme = lib.mkForce "kanagawa-transparent";
      autoupdate = false;
    };
  };

  home.shellAliases = rec {
    oc = "opencode";
    occ = "${oc} --continue";
  };

  xdg.configFile."opencode/themes/kanagawa-transparent.json".source =
    ./theme-kanagawa-transparent.json;
}
