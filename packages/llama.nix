{
  lib,
  stdenv,
  cmake,
  ninja,
  git,
  fetchFromGitHub,
  shaderc,
  spirv-headers,
  vulkan-headers,
  vulkan-loader,
  version,
  vulkanSupport ? false,
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
    # `glslc` compiles the Vulkan compute shaders at build time.
  ]
  ++ lib.optionals vulkanSupport [ shaderc ];

  buildInputs = lib.optionals vulkanSupport [
    spirv-headers
    vulkan-headers
    vulkan-loader
  ];

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DBUILD_SHARED_LIBS=ON"
    "-DGGML_CPU=ON"
    # Build every x86 CPU variant (AVX2/FMA, AVX512, ...) as separate backend
    # libraries so ggml picks the best one at runtime. Without this the generic
    # x86-64 build disables AVX/AVX2/FMA entirely, which is dramatically slower.
    "-DGGML_CPU_ALL_VARIANTS=ON"
    "-DGGML_VULKAN=${if vulkanSupport then "ON" else "OFF"}"
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
