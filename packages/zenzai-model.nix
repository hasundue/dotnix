{
  lib,
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation {
  pname = "zenzai-model";
  # Hazkey's own download button still points at zenz-v3.1-small (that URL was
  # last touched in 2026-02, before v3.2 was published). v3.2 is the same size,
  # newer, and Apache-2.0 licensed, so prefer it here.
  version = "3.2-small-q5_k_m";

  src = fetchurl {
    url = "https://huggingface.co/Miwa-Keita/zenz-v3.2-small-gguf/resolve/main/ggml-model-Q5_K_M.gguf";
    hash = "sha256-KcIj1MIzJ7gP0T67WrJVUFekYxeZfV2jkVhP++8NtnM=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm644 "$src" "$out/share/zenzai.gguf"
    runHook postInstall
  '';

  meta = {
    description = "Zenzai model (zenz-v3.2-small, Q5_K_M GGUF) for Hazkey";
    homepage = "https://huggingface.co/Miwa-Keita/zenz-v3.2-small-gguf";
    license = lib.licenses.asl20;
    platforms = lib.platforms.all;
  };
}
