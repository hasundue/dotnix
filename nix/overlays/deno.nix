final: prev: 
{
  deno = prev.deno.override (oldAttrs: {
    rustPlatform.buildRustPackage = args:
      final.rustPlatform.buildRustPackage (
        args // rec {
          version = "1.41.2";
          src = final.fetchFromGitHub {
            owner = "denoland";
            repo = args.pname;
            rev = "v${version}";
            hash = "sha256-l8He7EM9n8r7OTC6jN6F8ldf3INXxEeaUI1u6AfR7RI=";
          };
          cargoHash = "sha256-T+6b4bGx7y/7E0CIacKFQ32DCAiNFXFi15ibq7rDfI4=";
        }
      );
  });
}
