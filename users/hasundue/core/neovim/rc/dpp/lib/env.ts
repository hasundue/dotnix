import { join } from "./std/path.ts";

/** @example /home/username */
export const $HOME = Deno.env.get("HOME")!;

/** @example ~/.cache */
export const $XDG_CACHE_HOME = Deno.env.get("XDG_CACHE_HOME")!;

/** @example ~/.config */
export const $XDG_CONFIG_HOME = Deno.env.get("XDG_CONFIG_HOME")!;

/** @example ~/.local/share */
export const $XDG_DATA_HOME = Deno.env.get("XDG_DATA_HOME")!;

/** @example ~/.cache/dpp */
export const $CACHE = join($XDG_CACHE_HOME, "dpp");

/** @example ~/.config/nvim */
export const $CONFIG = join($XDG_CONFIG_HOME, "nvim");

/** @example ~/.local/share/nvim */
export const $DATA = join($XDG_DATA_HOME, "nvim");
