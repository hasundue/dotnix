export const HOOK_FILE_MAP = {
  hook_add: "hook_add.vim",
  hook_source: "hook_source.vim",
  lua_add: "hook_add.lua",
  lua_source: "hook_source.lua",
} as const;

export const HOOK_FILE_ENTRIES = Object.entries(HOOK_FILE_MAP);
