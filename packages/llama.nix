{
  lib,
  stdenv,
  cmake,
  ninja,
  git,
  fetchFromGitHub,
  version,
}:

stdenv.mkDerivation {
  pname = "hazkey-llama";
  inherit version;

  src = fetchFromGitHub {
    owner = "7ka-hiira";
    repo = "llama.cpp";
    rev = "10295c26a2a18c3c48863b179c5e6bf34a4057d1";
    hash = "sha256-23GOpDbrr6MgtjWTQxNn7M1+7l4/xJQNEMetVRgtt9U=";
  };

  strictDeps = true;
  __structuredAttrs = true;

  nativeBuildInputs = [
    cmake
    ninja
    git
  ];

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DBUILD_SHARED_LIBS=ON"
    "-DGGML_CPU=ON"
    "-DGGML_VULKAN=OFF"
    "-DGGML_CUDA=OFF"
    "-DGGML_HIP=OFF"
    "-DGGML_BACKEND_DL=ON"
    "-DLLAMA_CURL=OFF"
    "-DLLAMA_STANDALONE=OFF"
    "-DLLAMA_BUILD_TESTS=OFF"
    "-DLLAMA_BUILD_EXAMPLES=OFF"
    "-DLLAMA_BUILD_TOOLS=OFF"
  ];

  meta = {
    description = "llama.cpp (7ka-hiira fork) providing libllama for Hazkey Zenzai";
    homepage = "https://github.com/7ka-hiira/llama.cpp";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
