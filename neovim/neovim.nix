{ pkgs, lib, ... }:

let
  normalizeModule =
    { config ? null
    , packages ? [ ]
    , plugins ? [ ]
    } @ attrs: attrs;

  toLuaModuleName = path: with lib;
    removePrefix ((toString ../lua) + "/") (removeSuffix ".lua" (toString path));

  formatRequireLine = path: ''require("${toLuaModuleName path}")'';

  mergeModules = modules: with lib;
    let
      mergeAttr = a: b: if isList a then b ++ a else b ++ [ a ];
      merged = foldAttrs mergeAttr [ ] (map normalizeModule modules);
    in
    removeAttrs merged [ "config" ] // { configs = merged.config; };

  wrapNeovim = { configs, packages, plugins }:
    let
      neovimConfig = pkgs.neovimUtils.makeNeovimConfig { };
      configDir = lib.incl ../. configs;
      requireLines = lib.concatLines (map formatRequireLine configs);
    in
    with pkgs; wrapNeovimUnstable neovim-unwrapped (neovimConfig // {
      inherit plugins;

      luaRcContent = ''
        vim.opt.runtimepath:append("${configDir}");
        ${requireLines}
      '';

      wrapperArgs = neovimConfig.wrapperArgs
        ++ [ "--suffix" "PATH" ":" (lib.makeBinPath packages) ];

      wrapRc = true; # make sure to wrap the rc file for `-u` option

      withNodeJs = false;
      withPython3 = false;
      withRuby = false;
    });
in
{ modules ? [ ] }: wrapNeovim (mergeModules modules)
