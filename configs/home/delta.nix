{ ... }:
let
  commonArgs = "--paging=never --minus-style='syntax auto'";
in
{
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      "syntax-theme" = "base16";
      "side-by-side" = "140";
      "minus-style" = "syntax auto";
    };
  };

  programs.lazygit.settings.git.diffRenderers = [
    {
      command = "delta --{{colorScheme}} ${commonArgs} --side-by-side={{if gt .width 140}}true{{else}}false{{end}}";
    }
  ];

  programs.worktrunk.settings.switch.picker.pager = "delta ${commonArgs} --side-by-side=false";
}
