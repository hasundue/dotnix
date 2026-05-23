{ ... }:

{
  services.syncthing = {
    enable = true;
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      devices = {
        x1carbon = {
          id = "RIMQVCF-3UF3DLT-HDJJPKP-AB6K6PS-YVDT5QQ-6QNVW3B-4FWXORC-ALIY6QC";
        };
        phone = {
          id = "YEVQBMC-UUKJZG4-OKFY6ED-7OB33ZF-EVDSUYR-XTVK26J-TRQMQKG-77EUDAY";
        };
      };
      folders = {
        "~/notes" = {
          id = "notes";
          label = "Obsidian Vault";
          type = "sendreceive";
          devices = [
            "x1carbon"
            "phone"
          ];
          versioning = {
            type = "trashcan";
            params = {
              cleanoutDays = "30";
            };
          };
        };
      };
    };
  };

}
