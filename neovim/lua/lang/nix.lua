require("core.lsp").setup("nil_ls", {
  cmd = { "nil" },
  settings = {
    ["nil"] = {
      formatting = {
        command = { "nixpkgs-fmt" },
      },
    },
    nix = {
      flake = {
        autoArchive = true,
      },
    },
  },
})
