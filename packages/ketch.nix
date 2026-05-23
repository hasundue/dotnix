{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "ketch";
  version = "0.7.1";

  src = fetchFromGitHub {
    owner = "1broseidon";
    repo = "ketch";
    rev = "v${version}";
    hash = "sha256-tZO65bhTU6h9V6GprQuAYzPTtnfUpv7Jlh2h54vV7/c=";
  };

  vendorHash = "sha256-m3IwAYsczsxcVk9fay+f2AsNjmXoPk7NS0abES6b594=";

  meta = {
    description = "Fast stateless CLI for web search, code search, library docs, and scraping";
    homepage = "https://github.com/1broseidon/ketch";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "ketch";
  };
}
