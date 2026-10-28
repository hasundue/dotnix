{
  description = "hasundue's system configuration";
  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [ "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=" ];
  };
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    nixpkgs-mcp-nixos.url = "github:nixos/nixpkgs?ref=d8a0e4a8091f";
    nixos-hardware = {
      url = "github:nixos/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-compat = {
      url = "github:nix-community/flake-compat";
      flake = false;
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/nixos-wsl";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
    };
    stylix = {
      # TODO: revert to github:nix-community/stylix once
      # https://github.com/nix-community/stylix/pull/2503 is merged.
      url = "github:nix-community/stylix/pull/2503/head";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-addons = {
      url = "sourcehut:~rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    models-dev = {
      url = "github:anomalyco/models.dev";
      flake = false;
    };
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
    };
    lean4-skills = {
      url = "github:cameronfreer/lean4-skills";
      flake = false;
    };
    rpiv-mono = {
      url = "github:hasundue/rpiv-mono";
      flake = false;
    };
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents-nix = {
      url = "github:numtide/llm-agents.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    python-validity = {
      url = "github:viktor-grunwaldt/t480-fingerprint-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        pyproject-nix.follows = "pyproject-nix";
        uv2nix.follows = "uv2nix";
      };
    };
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    systems.url = "github:nix-systems/default";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        pyproject-nix.follows = "pyproject-nix";
      };
    };
    nvim = {
      url = "github:hasundue/nvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      agenix,
      home-manager,
      mcp-servers-nix,
      nixpkgs,
      nixpkgs-master,
      nvim,
      llm-agents-nix,
      self,
      stylix,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;
      overlays = [
        self.overlays.temporal # This must come first
        agenix.overlays.default
        nvim.overlays.default
        llm-agents-nix.overlays.shared-nixpkgs
      ]
      ++ (self.overlays |> lib.filterAttrs (n: v: n != "temporal") |> lib.attrValues);
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      pkgsFor = lib.genAttrs systems (
        system:
        import nixpkgs {
          inherit overlays system;
          config = {
            allowUnfree = true;
            # Zotero still bundles the EOL Firefox ESR 140 runtime; drop this
            # once nixpkgs switches its Zotero package to a supported ESR.
            permittedInsecurePackages = [ "firefox-esr-140-bin-unwrapped-140.17.0esr" ];
          };
        }
        // self.packages.${system}
      );
      metaConfig = system: {
        # Make sure to avoid evaluation of nixpkgs
        _module.args.pkgs = lib.mkForce pkgsFor.${system};
        # Consumed by ./nixos/_overlays-compat.nix
        nix.nixPath = [ "nixos-config=${self.outPath}" ];
        nixpkgs.overlays = overlays;
      };
      nixosSystem =
        name:
        {
          system,
          modules ? [ ],
        }:
        lib.nixosSystem {
          inherit system;
          modules = [
            {
              home-manager.sharedModules = [
                agenix.homeManagerModules.default
                mcp-servers-nix.homeManagerModules.default
              ];
            }
            (metaConfig system)
            home-manager.nixosModules.home-manager
            stylix.nixosModules.stylix
            ./configs/stylix.nix
          ]
          ++ modules;
        };
      username = "hasundue";
      homeConfig =
        {
          system,
          modules ? [ ],
        }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor.${system};
          modules = [
            {
              home.homeDirectory = "/home/${username}";
            }
            (metaConfig system)
            agenix.homeManagerModules.default
            mcp-servers-nix.homeManagerModules.default
            stylix.homeModules.stylix
            ./configs/stylix.nix
            ./configs/home
          ]
          ++ modules;
        };
      forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
    in
    {
      devShells = forEachSystem (
        pkgs:
        lib.mapAttrs' (
          name: _:
          lib.nameValuePair (lib.removeSuffix ".nix" name) (
            import ./shells/${name} {
              inherit pkgs;
              inherit (inputs) git-hooks-nix treefmt-nix;
            }
          )
        ) (builtins.readDir ./shells)
      );
      nixosConfigurations = lib.mapAttrs nixosSystem {
        # Thinkpad X1 Carbon 5th Gen
        x1carbon = {
          system = "x86_64-linux";
          modules = with inputs; [
            nixos-hardware.nixosModules.lenovo-thinkpad-x1-extreme
            python-validity.nixosModules."06cb-009a-fingerprint-sensor"
            ./configs/hosts/x1carbon
          ];
        };
        # NixOS-WSL
        nixos = {
          system = "x86_64-linux";
          modules = with inputs; [
            nixos-wsl.nixosModules.default
            ./configs/hosts/wsl
          ];
        };
      };
      overlays = import ./overlays // {
        pristine = import ./overlays/pristine.nix {
          inherit (inputs)
            firefox-addons
            models-dev
            rpiv-mono
            ;
        };
        temporal = import ./overlays/temporal.nix {
          mcp-nixos = inputs.nixpkgs-mcp-nixos;
        };
        lean4-skills = final: prev: {
          lean4-skills-src = inputs.lean4-skills;
        };
      };
      packages = forEachSystem (pkgs: {
        ketch = pkgs.callPackage ./packages/ketch.nix { };
        zotero-mcp = pkgs.callPackage ./packages/zotero-mcp.nix {
          inherit (inputs)
            pyproject-build-systems
            pyproject-nix
            uv2nix
            ;
        };
      });
      homeConfigurations =
        lib.mapAttrs' (hostname: v: homeConfig v |> lib.nameValuePair "${username}@${hostname}")
          {
            x1carbon = {
              system = "x86_64-linux";
              modules = [ ./configs/home/desktop ];
            };
            nixos.system = "x86_64-linux";
          };
      apps = forEachSystem (
        pkgs:
        let
          # Flags recommended by nix-output-monitor for pretty human output
          nomOpts = "--log-format internal-json -v";
          # Run a nixos-rebuild action as the nixos-{build,test,switch,boot}
          # apps. The toplevel already includes home-manager (used as a NixOS
          # module), so one build covers both; activation updates the system
          # profile, so rollback keeps working. Elevation: as a normal user
          # --elevate=sudo lets sudo prompt at activation time (not at all
          # with a warm timestamp or NOPASSWD). Under `sudo nix run` no flag
          # is passed, so ng neither warns nor asks for the password a second
          # time (--ask-elevate-password has no root check in ng and would
          # always prompt).
          nixosApp =
            action:
            pkgs.writeShellScriptBin "nixos-${action}" ''
              set -euo pipefail
              args=(--flake '.#'$(hostname))
              if [ "$(id -u)" -ne 0 ]; then
                args+=(--elevate=sudo)
              fi
              exec nixos-rebuild ${action} "''${args[@]}" "$@"
            '';
          opencodeConfig =
            let
              homeConfig = self.homeConfigurations."hasundue@x1carbon";
              opencodeFiles = lib.mapAttrsToList (name: file: {
                inherit name;
                path = file.source;
              }) (lib.filterAttrs (name: _: lib.hasPrefix "opencode/" name) homeConfig.config.xdg.configFile);
            in
            pkgs.linkFarm "opencode-config" opencodeFiles;
        in
        {
          # Build home-manager generation (no sudo)
          "home-build" = {
            type = "app";
            program = "${pkgs.writeShellScriptBin "home-build" ''
              set -euo pipefail
              target='.#homeConfigurations."hasundue@'"$(hostname)"'".activationPackage'
              if [ -t 1 ] && [ -z "''${NOM_DISABLE:-}" ]; then
                exec nix build "$target" \
                  ${nomOpts} "$@" -o result-home 2>&1 | ${pkgs.nix-output-monitor}/bin/nom --json
              else
                exec nix build "$target" \
                  "$@" -o result-home
              fi
            ''}/bin/home-build";
          };

          # Activate previously built home-manager generation (no sudo)
          "home-switch" = {
            type = "app";
            program = "${pkgs.writeShellScriptBin "home-switch" ''
              set -euo pipefail
              if [ ! -L ./result-home ]; then
                echo "error: no result-home symlink found. Run 'nix run .#home-build' first." >&2
                exit 1
              fi
              exec ./result-home/activate "$@"
            ''}/bin/home-switch";
          };

          # Build NixOS + home-manager (no sudo; leaves ./result)
          "nixos-build" = {
            type = "app";
            program = "${pkgs.writeShellScriptBin "nixos-build" ''
              set -euo pipefail
              if [ -t 1 ] && [ -z "''${NOM_DISABLE:-}" ]; then
                exec nixos-rebuild build --flake '.#'$(hostname) \
                  ${nomOpts} "$@" 2>&1 | ${pkgs.nix-output-monitor}/bin/nom --json
              else
                exec nixos-rebuild build --flake '.#'$(hostname) "$@"
              fi
            ''}/bin/nixos-build";
          };

          # Switch to the new toplevel
          "nixos-switch" = {
            type = "app";
            program = "${nixosApp "switch"}/bin/nixos-switch";
          };

          # Test the new toplevel without making it the default
          "nixos-test" = {
            type = "app";
            program = "${nixosApp "test"}/bin/nixos-test";
          };

          # Set the boot entry for the next reboot
          "nixos-boot" = {
            type = "app";
            program = "${nixosApp "boot"}/bin/nixos-boot";
          };

          # Run opencode with ephemeral XDG_CONFIG_HOME from flake-tracked config
          opencode = {
            type = "app";
            program = "${pkgs.writeShellScriptBin "opencode" ''
              export XDG_CONFIG_HOME="$(mktemp -d)"
              cp -rsf "${opencodeConfig}/"* "$XDG_CONFIG_HOME/"
              exec ${pkgs.llm-agents.opencode}/bin/opencode "$@"
            ''}/bin/opencode";
          };
        }
      );
      templates = {
        default = {
          path = ./templates/default;
          description = "A minimal Nix flake template";
        };
      };
    };
}
