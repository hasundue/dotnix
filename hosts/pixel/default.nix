{ pkgs, ... } @ args:

{
  environment.packages = with pkgs; [
    git
    vim
  ];

  home-manager = {
    useGlobalPkgs = true;
    config = import ../home args;
  };

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  system.stateVersion = "24.05";

  time.timeZone = "Asia/Tokyo";

  terminal.font = "${pkgs.nerd-fonts.caskaydia-cove}/fonts/ttf/CaskaydiaCove-Regular.ttf";
}
