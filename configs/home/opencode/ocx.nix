{
  pkgs,
  lib,
  ...
}:
let
  ocxBin = "${lib.getExe pkgs.ocx}";
in
{
  home.packages = with pkgs; [ ocx ];

  home.activation.ocxInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${ocxBin} init --global 2>/dev/null || true
    ${ocxBin} profile add ws --source kit/ws --from https://ocx-kit.kdco.dev --global 2>/dev/null || true
  '';
}
