import {
  ClosedGroup,
  Group,
} from "https://esm.sh/gh/hasundue/dpp-helper/mod.ts";

async function readTextFile(path: string) {
  return await Deno.readTextFile(new URL(path, import.meta.url));
}

export const PLUGINS = ClosedGroup(
  // Bootstrap (dpp.vim)
  ...Group({ lazy: false, rtp: "" }, [
    { repo: "Shougo/dpp.vim" },
    { repo: "Shougo/dpp-ext-lazy" },
  ]),
  // Loaded eventually
  ...Group({ on_event: ["CursorHold"] }, [
    { repo: "vim-denops/denops.vim" },
  ]),
  // vim-floaterm
  {
    repo: "voldikss/vim-floaterm",
    on_cmd: ["Floaterm*"],
    hook_add: await readTextFile("../floaterm.vim"),
  },
);
