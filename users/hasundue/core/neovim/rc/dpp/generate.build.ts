import type { ClosedGroup } from "./lib/groups.ts";
import { $HOME } from "./lib/env.ts";

const PLACEHOLDER = "    /* PLACEHOLDER */";

async function generateFlake(
  plugins: ClosedGroup,
) {
  const template = await Deno.readTextFile(
    new URL("./flake_template.nix", import.meta.url),
  );

  const lines = plugins.map((it) => {
    const { name, repo } = it;
    const url = repo.startsWith("~")
      ? `git+file:${repo.replace("~", $HOME)}`
      : `github:${repo}`;
    return `    ${name} = { url = "${url}"; flake = false; };`;
  });

  await Deno.writeTextFile(
    new URL("../../flake.nix", import.meta.url),
    template.replace(PLACEHOLDER, lines.join("\n")),
  );
}

if (import.meta.main) {
  const { PLUGINS } = await import("./plugins.ts");
  await generateFlake(PLUGINS);
}
