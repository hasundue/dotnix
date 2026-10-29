let
  # Dedicated age identity, kept out of git at ~/.config/age/keys.txt.
  # Deliberately not the SSH key used for GitHub etc., so that a leak of one
  # does not compromise the other.
  x1carbon = "age10z9exudppuev72j9azx3pvjvamtc899p93p7zyft68u2s6w8wsyqv65jah";

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
