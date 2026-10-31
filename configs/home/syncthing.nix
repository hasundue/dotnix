{
  lib,
  ...
}:

let
  # TODO: replace this with the higame host's `syncthing device-id`. The
  # sentinel keeps the folder local-only until then, so neither host creates a
  # phantom device that can never connect.
  higameDeviceId = "REPLACE-WITH-HIGAME-DEVICE-ID";
  higame = higameDeviceId != "REPLACE-WITH-HIGAME-DEVICE-ID";
in
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
      }
      // lib.optionalAttrs higame {
        # The attribute name is only a label; `name` is what peers display.
        # On higame this same ID is the local device, so it also names the device.
        higame = {
          id = higameDeviceId;
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
          devices = [ "x1carbon" ] ++ lib.optional higame "higame";
        };
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
