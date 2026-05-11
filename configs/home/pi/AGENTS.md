# Pi Package Config

Nix-managed pi extension packages. Declared in `package.json`, locked in
`package-lock.json`, built by Nix (`importNpmLock.buildNodeModules`).

- `extensions/` — local extension sources
- `themes/` — theme files
- `skills/` — skill directories
- `prompts/` — prompt templates

**Important:** Never run `npm install` to update dependencies — use
`npm install --package-lock-only` and let Nix handle the actual build.
