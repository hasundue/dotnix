import {
  $HOME,
  ClosedGroup,
} from "https://esm.sh/gh/hasundue/dpp-helper/mod.ts";

const PLACEHOLDER = "    /* PLACEHOLDER */";

const TEMPLATE = `{
  description = "hasundue's Neovim plugins (auto-generated)";

  inputs = {
${PLACEHOLDER}
  };

  outputs = inputs: {
    plugins = inputs;
  };
}`;

async function generateFlake(
  plugins: ClosedGroup,
) {
  const pluginLines = plugins.map((it) => {
    const { name, repo } = it;
    const url = repo.startsWith("~")
      ? `git+file:${repo.replace("~", $HOME)}`
      : `github:${repo}`;
    return `    "${name}" = { url = "${url}"; flake = false; };`;
  });
  await Deno.writeTextFile(
    new URL("./flake.nix", import.meta.url),
    TEMPLATE.replace(PLACEHOLDER, pluginLines.join("\n")),
  );
}

if (import.meta.main) {
  const { PLUGINS } = await import(
    new URL("./rc/dpp/plugins.ts", import.meta.url).href
  );
  await generateFlake(PLUGINS);
}
