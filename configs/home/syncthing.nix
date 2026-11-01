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
        higame = {
          id = "FF5LJNU-BIP2O7K-EKJRPFQ-JVZG4NN-NKLLGWE-JHYQPZW-FTHXTVI-HDTF4QS";
          name = "higame";
        };
      };
      folders = {
        # Session transcripts are self-contained JSONL files, so resuming them
        # on another host just needs the files. Keep the scope to these two
        # devices: transcripts may contain file contents and tool output.
        "~/.pi/agent/sessions" = {
          id = "pi-sessions";
          label = "Pi sessions";
          type = "sendreceive";
          devices = [
            "x1carbon"
            "higame"
          ];
        };
        "~/notes" = {
          id = "notes";
          label = "Obsidian Vault";
          type = "sendreceive";
          devices = [
            "x1carbon"
            "higame"
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
