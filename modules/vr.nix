{
  config,
  pkgs,
  lib,
  ...
}: let
  slimevr_exe = config.lib.nixGL.wrap pkgs.slimevr;
  slimevr = pkgs.writeShellScriptBin "slimevr" "WEBKIT_DISABLE_DMABUF_RENDERER=1 ${slimevr_exe}/bin/slimevr $@";
  wlx-overlay-s = pkgs.wlx-overlay-s.overrideAttrs (prevAttrs: {
    postInstall = ''
      patchelf $out/bin/wlx-overlay-s \
        --add-needed ${lib.getLib pkgs.libGL}/lib/libEGL.so.1 \
        --add-needed ${lib.getLib pkgs.libGL}/lib/libGL.so.1 \
        --add-needed ${lib.getLib pkgs.vulkan-loader}/lib/libvulkan.so.1 \
        --add-needed ${lib.getLib pkgs.libuuid}/lib/libuuid.so.1
    '';
    #--add-needed ${lib.getLib wayland}/lib/libwayland-client.so.0 \
    #--add-needed ${lib.getLib libxkbcommon}/lib/libxkbcommon.so.0 \
  });
  baballonia = import ./vr_baballonia.nix {inherit pkgs;};
  #index_camera_passthrough = import ./vr_icp.nix {inherit pkgs;};
in {
  home.packages = [
    slimevr
    wlx-overlay-s
    #(config.lib.nixGL.wrap baballonia)
    #baballonia
    #index_camera_passthrough
  ];
}
