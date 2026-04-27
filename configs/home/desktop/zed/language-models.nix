{ pkgs, lib, ... }:
let
  provider = "opencode-go";
  src = pkgs.modelsDevSource;
  providerDir = "${src}/providers/${provider}";
  providerConfig = builtins.fromTOML (builtins.readFile "${providerDir}/provider.toml");

  modelEntries = lib.filterAttrs (n: t: t == "regular" && lib.hasSuffix ".toml" n) (
    builtins.readDir "${providerDir}/models"
  );

  parseModel =
    filename:
    let
      data = builtins.fromTOML (builtins.readFile "${providerDir}/models/${filename}");
      id = lib.removeSuffix ".toml" filename;
    in
    {
      name = id;
      display_name = data.name;
      max_tokens = data.limit.context;
      max_output_tokens = data.limit.output;
      max_completion_tokens = data.limit.output;
      capabilities = {
        tools = data.tool_call or false;
        images = lib.elem "image" (data.modalities.input or [ ]);
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
