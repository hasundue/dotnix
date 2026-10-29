# Entry point for the `agenix` CLI.
#
# agenix looks for a file called agenix-rules.nix in the current directory and
# then in every parent directory, and treats each attribute name as a path
# relative to the rules file. This adapter re-exports the per-secret rules in
# ./configs/home/agenix with repo-relative names, so the CLI works from anywhere
# in the repository without setting AGENIX_RULES (a devShell cannot provide it:
# `nix develop` only exposes store paths, which are read-only, and the
# home-manager module imports the real file directly).
#
# The paths passed to `agenix -e` / `-d` are relative to the repository root:
#   agenix -e configs/home/agenix/api/brave.age
let
  rules = import ./configs/home/agenix/agenix-rules.nix;
  prefix = "configs/home/agenix/";
in
builtins.listToAttrs (
  map (name: {
    name = prefix + name;
    value = rules.${name};
  }) (builtins.attrNames rules)
)
