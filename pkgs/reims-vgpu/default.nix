{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchgit,
  rustPlatform,
  cargo,
  rustc,
  pkg-config,
  python3,
  python3Packages,
  ninja,
  dtc,
  glib,
  libslirp,
  libusb1,
  ncurses,
  pixman,
  zlib,
  llvmPackages,
  spirv-tools,
  makeWrapper,
}:
let
  qemuPython = python3.withPackages (
    ps: with ps; [
      meson
      pycotap
      qemu-qmp
      setuptools
      wheel
      pip
    ]
  );
in
stdenv.mkDerivation (finalAttrs: {
  pname = "reims-vgpu";
  version = "0-unstable-2026-07-30";

  src = fetchFromGitHub {
    owner = "steelbrain";
    repo = "reims-vgpu";
    rev = "9a5299a0b77202c5d9e7262efe216faca1f5c8b2";
    hash = "sha256-tUdazPrqawGp8AFvhwVg/G1eUWJtBXyaxUuSbjYA51I=";
  };

  qemuSrc = fetchFromGitHub {
    owner = "steelbrain";
    repo = "qemu-reims-vgpu";
    rev = "999c6d791995a4f6cff79a2473b596bca64bfacc";
    hash = "sha256-pbWslshbXTg+qC9WWxgnwZ3Q0/CoHcg/PEOVtpb1EJg=";
  };

  keycodemapdbSrc = fetchgit {
    url = "https://gitlab.com/qemu-project/keycodemapdb.git";
    rev = "f5772a62ec52591ff6870b7e8ef32482371f22c6";
    hash = "sha256-EQrnBAXQhllbVCHpOsgREzYGncMUPEIoWFGnjo+hrH4=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) src;
    hash = "sha256-FlPtvcTMabHm3KB0ukvYVz2nWGIlCT3gyauCwSC8RUE=";
  };
  cargoRoot = "../..";

  nativeBuildInputs = [
    makeWrapper
    dtc
    ninja
    pkg-config
    qemuPython
    rustPlatform.cargoSetupHook
    cargo
    rustc
  ];

  buildInputs = [
    glib
    libslirp
    libusb1
    ncurses
    pixman
    zlib
  ];

  postUnpack = ''
    mv "$sourceRoot" reims-vgpu
    rm -rf reims-vgpu/vendor/qemu
    mkdir -p reims-vgpu/vendor/qemu
    cp -a "$qemuSrc"/. reims-vgpu/vendor/qemu
    chmod -R u+w reims-vgpu/vendor/qemu
    cp -a "$keycodemapdbSrc" reims-vgpu/vendor/qemu/subprojects/keycodemapdb
    sourceRoot=reims-vgpu/vendor/qemu
  '';

  configurePhase = ''
    runHook preConfigure
    cd "$NIX_BUILD_TOP/reims-vgpu/vendor/qemu"
    export REIMS_VGPU_BACKEND=vulkan
    ./configure \
      --prefix=$out \
      --target-list=x86_64-softmmu \
      --disable-tcg \
      --disable-docs \
      --disable-bsd-user \
      --disable-linux-user \
      --disable-tools
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    cd "$NIX_BUILD_TOP/reims-vgpu/vendor/qemu"
    ninja -C build qemu-system-x86_64
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 "$NIX_BUILD_TOP/reims-vgpu/vendor/qemu/build/qemu-system-x86_64" $out/bin/qemu-system-x86_64
    wrapProgram $out/bin/qemu-system-x86_64 \
      --prefix PATH : ${lib.makeBinPath [ llvmPackages.llvm spirv-tools ]}
    runHook postInstall
  '';

  meta = {
    description = "Patched QEMU with the experimental Reims vGPU for macOS guests";
    homepage = "https://github.com/steelbrain/reims-vgpu";
    license = lib.licenses.gpl2Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "qemu-system-x86_64";
  };
})
