{ ... }:
{
  programs.zed-editor.userSettings.language_models = {
    openai_compatible = {
      "OpenCode Go" = {
        api_url = "https://opencode.ai/zen/go/v1";
        available_models = [
          {
            name = "deepseek-v4-flash";
            display_name = "DeepSeek V4 Flash";
            max_tokens = 1000000;
            max_output_tokens = 384000;
            max_completion_tokens = 1000000;
            capabilities = {
              tools = true;
              images = false;
              parallel_tool_calls = false;
              prompt_cache_key = false;
              chat_completions = true;
            };
          }
          {
            name = "deepseek-v4-pro";
            display_name = "DeepSeek V4 Pro";
            max_tokens = 1000000;
            max_output_tokens = 384000;
            max_completion_tokens = 1000000;
            capabilities = {
              tools = true;
              images = false;
              parallel_tool_calls = false;
              prompt_cache_key = false;
              chat_completions = true;
            };
          }
          {
            name = "glm-5";
            display_name = "GLM-5";
            max_tokens = 204800;
            max_output_tokens = 131072;
            max_completion_tokens = 204800;
            capabilities = {
              tools = true;
              images = false;
              parallel_tool_calls = false;
              prompt_cache_key = false;
              chat_completions = true;
            };
          }
          {
            name = "glm-5.1";
            display_name = "GLM-5.1";
            max_tokens = 204800;
            max_output_tokens = 131072;
            max_completion_tokens = 204800;
            capabilities = {
              tools = true;
              images = false;
              parallel_tool_calls = false;
              prompt_cache_key = false;
              chat_completions = true;
            };
          }
          {
            name = "kimi-k2.5";
            display_name = "Kimi K2.5";
            max_tokens = 262144;
            max_output_tokens = 65536;
            max_completion_tokens = 262144;
            capabilities = {
              tools = true;
              images = true;
              parallel_tool_calls = false;
              prompt_cache_key = false;
              chat_completions = true;
            };
          }
          {
            name = "kimi-k2.6";
            display_name = "Kimi K2.6 (3x limits)";
            max_tokens = 262144;
            max_output_tokens = 65536;
            max_completion_tokens = 262144;
            capabilities = {
              tools = true;
              images = true;
              parallel_tool_calls = false;
              prompt_cache_key = false;
              chat_completions = true;
            };
          }
          {
            name = "mimo-v2-omni";
            display_name = "MiMo V2 Omni";
            max_tokens = 262144;
            max_output_tokens = 128000;
            max_completion_tokens = 262144;
            capabilities = {
              tools = true;
              images = true;
              parallel_tool_calls = false;
              prompt_cache_key = false;
              chat_completions = true;
            };
          }
          {
            name = "mimo-v2-pro";
            display_name = "MiMo V2 Pro";
            max_tokens = 1048576;
            max_output_tokens = 128000;
            max_completion_tokens = 1048576;
            capabilities = {
              tools = true;
              images = false;
              parallel_tool_calls = false;
              prompt_cache_key = false;
              chat_completions = true;
            };
          }
          {
            name = "mimo-v2.5";
            display_name = "MiMo V2.5";
            max_tokens = 262144;
            max_output_tokens = 128000;
            max_completion_tokens = 262144;
            capabilities = {
              tools = true;
              images = true;
              parallel_tool_calls = false;
              prompt_cache_key = false;
              chat_completions = true;
            };
          }
          {
            name = "mimo-v2.5-pro";
            display_name = "MiMo V2.5 Pro";
            max_tokens = 1048576;
            max_output_tokens = 128000;
            max_completion_tokens = 1048576;
            capabilities = {
              tools = true;
              images = false;
              parallel_tool_calls = false;
              prompt_cache_key = false;
              chat_completions = true;
            };
          }
          {
            name = "minimax-m2.5";
            display_name = "MiniMax M2.5";
            max_tokens = 204800;
            max_output_tokens = 65536;
            max_completion_tokens = 204800;
            capabilities = {
              tools = true;
              images = false;
              parallel_tool_calls = false;
              prompt_cache_key = false;
              chat_completions = true;
            };
          }
          {
            name = "minimax-m2.7";
            display_name = "MiniMax M2.7";
            max_tokens = 204800;
            max_output_tokens = 131072;
            max_completion_tokens = 204800;
            capabilities = {
              tools = true;
              images = false;
              parallel_tool_calls = false;
              prompt_cache_key = false;
              chat_completions = true;
            };
          }
          {
            name = "qwen3.5-plus";
            display_name = "Qwen3.5 Plus";
            max_tokens = 262144;
            max_output_tokens = 65536;
            max_completion_tokens = 262144;
            capabilities = {
              tools = true;
              images = true;
              parallel_tool_calls = false;
              prompt_cache_key = false;
              chat_completions = true;
            };
          }
          {
            name = "qwen3.6-plus";
            display_name = "Qwen3.6 Plus";
            max_tokens = 262144;
            max_output_tokens = 65536;
            max_completion_tokens = 262144;
            capabilities = {
              tools = true;
              images = true;
              parallel_tool_calls = false;
              prompt_cache_key = false;
              chat_completions = true;
            };
          }
        ];
      };
    };
  };
}
