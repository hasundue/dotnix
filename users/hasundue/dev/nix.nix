{
  home = {
    shellAliases = rec {
      nd = "nix develop";
      ndb = "${nd} -c build";
      nds = "${nd} -c switch";
      ndu = "${nd} -c update";

      nf = "nix flake";
      nfc = "${nf} check";
      nfs = "${nf} show";
      nfu = "${nf} update";
    };
  };
}
