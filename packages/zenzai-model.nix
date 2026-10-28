{
  lib,
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation {
  pname = "zenzai-model";
  version = "3.1-small-q5_k_m";

  src = fetchurl {
    url = "https://huggingface.co/Miwa-Keita/zenz-v3.1-small-gguf/resolve/main/ggml-model-Q5_K_M.gguf";
    hash = "sha256-TekwwGvvjCY6oapAaEryBttM4bljdbO47Q6lCOCxT2w=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm644 "$src" "$out/share/zenzai.gguf"
    runHook postInstall
  '';

  meta = {
    description = "Zenzai model (zenz-v3.1-small, Q5_K_M GGUF) for Hazkey";
    homepage = "https://huggingface.co/Miwa-Keita/zenz-v3.1-small-gguf";
    license = lib.licenses.cc-by-sa-40;
    platforms = lib.platforms.all;
  };
}
