---
name: config-agent-skill
description: >-
  Register a new pi skill in the user's home-manager Nix configuration.
  Use when a skill needs to be deployed via home-manager (user-wide).
  Delegates file creation to create-skill, then handles Nix registration.
---

# Register a pi skill in the user config

Use this when asked to create a user-wide pi skill (a skill registered in the
Nix home-manager config). This is a specialization of `create-skill` — it calls
that skill for file creation, then wires the result into the Nix config.

## Process

### 1. Create skill files

Use `create-skill` to create the script and SKILL.md, specifying the destination
as `configs/home/pi/skills/<name>/` (user-wide, not the default
`.agents/skills/`).

### 2. Register in home-manager

Edit `configs/home/pi/default.nix` and add to the `home.file` set:

```nix
"skills/<name>/SKILL.md".source = ./skills/<name>/SKILL.md;
"skills/<name>/script.ts" = {
  source = ./skills/<name>/script.ts;
  executable = true;
};
```

### 3. Add environment variables (if needed)

If the skill needs an API key, add to `home.sessionVariables` in the same file:

```nix
home.sessionVariables = {
  EXA_API_KEY_FILE = exaKeyFile;
};
```

If the key is an age secret, add it to the `let` block at the top:

```nix
let
  exaKeyFile = config.age.secrets."api/exa".path;
};
```

### 4. Add agenix secret (if needed)

If the skill needs an encrypted secret, define it in
`configs/home/agenix/secrets.nix`.

### 5. Validate

```bash
nix eval .#homeConfigurations."hasundue@x1carbon".config.home.file
```

### 6. Notify user to switch

Tell the user to run `home-manager switch` to deploy.

## Reference

- `create-skill` — creates the skill script and SKILL.md
- `configs/home/pi/default.nix` — pi skill registration file
- `configs/home/agenix/secrets.nix` — agenix secret definitions
