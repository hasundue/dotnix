let
  # The machine's SSH identity. agenix injects it as a decryption identity
  # automatically, so the CLI and agenix.service work without extra plumbing.
  x1carbon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEdXjo4PDOtl3N8XMhNK/bYNrcHvvq/ereNMU+97GEoI";

  secrets = [
    "api/brave"
    "api/context7"
    "api/copilot"
    "api/exa"
    "api/gemini"
    "api/opencode-go"
    "github/claude-code"
  ];

  toAttrs = name: {
    name = "${name}.age";
    value.publicKeys = [ x1carbon ];
  };
in
builtins.listToAttrs (builtins.map toAttrs secrets)
