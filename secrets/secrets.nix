let
  x1carbon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEdXjo4PDOtl3N8XMhNK/bYNrcHvvq/ereNMU+97GEoI";

  secrets = [
    "api/brave"
    "api/copilot"
    "api/gemini"
  ];

  toAttrs = name: {
    name = "${name}.age";
    value.publicKeys = [ x1carbon ];
  };
in
builtins.listToAttrs (builtins.map toAttrs secrets)
