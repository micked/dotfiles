# Monado + libsurvive built from git HEAD.
# Sources are flake inputs (flake = false); bump with:
#   nix flake update monado-src libsurvive-src
{
  monado,
  libsurvive,
  monado-src,
  libsurvive-src,
}: let
  shortRev = src: builtins.substring 0 7 (src.rev or "dirty");
  date = src: builtins.substring 0 8 (src.lastModifiedDate or "19700101");
  gitVersion = src: "0-unstable-${date src}-${shortRev src}";

  libsurvive-git = libsurvive.overrideAttrs (_: {
    version = gitVersion libsurvive-src;
    src = libsurvive-src;
    # https://github.com/collabora/libsurvive/issues/272
    # (cnmatrix moved from libs/cnkalman/libs/ to libs/ upstream)
    postPatch = ''
      substituteInPlace survive.pc.in libs/cnkalman/cnkalman.pc.in libs/cnmatrix/cnmatrix.pc.in \
        --replace-fail '$'{exec_prefix}/@CMAKE_INSTALL_LIBDIR@ @CMAKE_INSTALL_FULL_LIBDIR@
    '';
  });
in
  (monado.override {libsurvive = libsurvive-git;}).overrideAttrs (_: {
    version = gitVersion monado-src;
    src = monado-src;
    # nixpkgs' patches target the 25.1.0 tag and are already upstream.
    patches = [];
    passthru.libsurvive = libsurvive-git;
  })
