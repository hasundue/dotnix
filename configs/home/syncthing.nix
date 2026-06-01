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
        pixel = {
          id = "EW3ELLD-XI2BP2D-M6B5K7L-EAQ74NZ-44YWVPR-VFWHFPF-46F22PH-CPXUJQW";
        };
      };
      folders = {
        "~/notes" = {
          id = "notes";
          label = "Obsidian Vault";
          type = "sendreceive";
          devices = [
            "x1carbon"
            "pixel"
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
