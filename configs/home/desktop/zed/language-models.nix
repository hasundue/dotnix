{ pkgs, lib, ... }:
let
  provider = "opencode-go";
  src = pkgs.modelsDevSource;
  providerDir = "${src}/providers/${provider}";
  providerConfig = builtins.fromTOML (builtins.readFile "${providerDir}/provider.toml");

  modelEntries = lib.filterAttrs (n: t: t == "regular" && lib.hasSuffix ".toml" n) (
    builtins.readDir "${providerDir}/models"
  );

  readToml = path: builtins.fromTOML (builtins.readFile path);

  # Provider entries only carry their overrides and may inherit from a
  # provider-agnostic model via `base_model = "<lab>/<model>"`.
  readModel =
    id:
    let
      data = readToml "${providerDir}/models/${id}.toml";
      base = if data ? base_model then readToml "${src}/models/${data.base_model}.toml" else { };
    in
    {
      inherit data base;
      limit = (base.limit or { }) // (data.limit or { });
      modalities = data.modalities or (base.modalities or { });
    };

  parseModel =
    filename:
    let
      id = lib.removeSuffix ".toml" filename;
      inherit (readModel id)
        data
        base
        limit
        modalities
        ;
      tools =
        if data ? capabilities && data.capabilities ? tools then
          data.capabilities.tools.supported or false
        else
          base.capabilities.tools.supported or false;
    in
    {
      name = id;
      display_name = data.name or (base.name or id);
      max_tokens = limit.context;
      max_output_tokens = limit.output;
      max_completion_tokens = limit.output;
      capabilities = {
        inherit tools;
        images = lib.any (m: m == "image" || lib.hasPrefix "image/" m) (modalities.input or [ ]);
        interleaved_reasoning = data.interleaved.field or null != null;
        parallel_tool_calls = false;
        prompt_cache_key = false;
        chat_completions = true;
      };
    };
in
{
  programs.zed-editor.userSettings.language_models = {
    openai_compatible = {
      "${providerConfig.name}" = {
        api_url = providerConfig.api;
        available_models = lib.mapAttrsToList (n: _: parseModel n) modelEntries;
      };
    };
  };
}
