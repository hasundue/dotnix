{
  description = "hasundue's Neovim plugins (auto-generated)";

  inputs = {
    /* PLACEHOLDER */
  };

  outputs = { nixpkgs, ... } @ inputs: {
    plugins = nixpkgs.lib.filterAttrs
      (name: value: name != "nixpkgs" && name != "_type" && name != "self")
      inputs;
  };
}
