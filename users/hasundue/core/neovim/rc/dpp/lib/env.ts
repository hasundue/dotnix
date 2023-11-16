import { join } from "./std/path.ts";

export const $XDG_DATA_HOME = Deno.env.get("XDG_DATA_HOME")!;
export const $XDG_CONFIG_HOME = Deno.env.get("XDG_CONFIG_HOME")!;

/** @example ~/.config/nvim */
export const $CONFIG = join($XDG_CONFIG_HOME, "nvim");

/** @example ~/.local/share/nvim */
export const $DATA = join($XDG_DATA_HOME, "nvim");
