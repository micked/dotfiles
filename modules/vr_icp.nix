{pkgs}:
pkgs.rustPlatform.buildRustPackage {
  pname = "index_camera_passthrough";
  version = "0d3ec30c5cd74e4a3df93d704ecf4a25136afd73";
  src = pkgs.fetchgit {
    url = "https://github.com/yshui/index_camera_passthrough.git";
    rev = "0d3ec30c5cd74e4a3df93d704ecf4a25136afd73";
    sha256 = "sha256-jldpVWnpWEA3bi3lzmG94uCaoZuL+xhaEAtFiZrSGc4=";
  };

  cargoHash = "sha256-c7+JXQz6Ur7o6R+OsndKCPoqErtvXxaoDyr34BeJ4yM=";
  buildFeatures = ["openvr"];

  nativeBuildInputs = with pkgs; [
    cmake
    pkg-config
    rustPlatform.bindgenHook
    llvmPackages_latest.libclang.lib
    pkgs.stdenv.cc.cc
    pkgs.glibc.dev
    linuxHeaders
  ];

  buildInputs = with pkgs; [
    udev
    vulkan-loader
    openxr-loader
    openvr
  ];

  RUSTC_BOOTSTRAP = true;

  postPatch = ''
    substituteInPlace Cargo.toml \
      --replace-fail \
        'openxr = { version = "0.17.1", optional = true }' \
        'openxr = { version = "0.17.1", optional = true, features = ["linked"] }'
  '';

  postInstall = ''
    patchelf $out/bin/index_camera_passthrough \
      --add-needed ${pkgs.lib.getLib pkgs.libuuid}/lib/libuuid.so.1
  '';

  env.SHADERC_LIB_DIR = "${pkgs.lib.getLib pkgs.shaderc}/lib";
}
