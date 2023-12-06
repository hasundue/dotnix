{ home-manager, stylix, ... }:

{
  imports = [
    home-manager.nixosModules.home-manager
    stylix.nixosModules.stylix
  ];

  i18n.defaultLocale = "en_US.UTF-8";

  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
  };

  system = {
    stateVersion = "23.11";
  };
}
