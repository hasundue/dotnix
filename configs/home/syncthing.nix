{
  lib,
  ...
}:

let
  # TODO: replace this with the WSL host's `syncthing device-id`. The sentinel
  # keeps the folder local-only until then, so neither host creates a phantom
  # device that can never connect.
  wslDeviceId = "REPLACE-WITH-WSL-DEVICE-ID";
  wsl = wslDeviceId != "REPLACE-WITH-WSL-DEVICE-ID";
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
      // lib.optionalAttrs wsl {
        nixos = {
          id = wslDeviceId;
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
          devices = [ "x1carbon" ] ++ lib.optional wsl "nixos";
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
