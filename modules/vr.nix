{
  # config,
  # osConfig,
  pkgs,
  ...
}: {
  # xdg.configFile."openxr/1/active_runtime.json".source = "${osConfig.services.monado.package}/share/openxr/1/openxr_monado.json";

  home.packages = [
    # slimevr
    pkgs.wayvr
    #(config.lib.nixGL.wrap baballonia)
    #baballonia
    #index_camera_passthrough
  ];

  # xdg.configFile."openvr/openvrpaths.vrpath".text = let
  #   steam = "${config.xdg.dataHome}/Steam";
  # in
  #   builtins.toJSON {
  #     version = 1;
  #     jsonid = "vrpathreg";

  #     external_drivers = null;
  #     config = ["${steam}/config"];

  #     log = ["${steam}/logs"];

  #     runtime = [
  #       "${pkgs.xrizer}/lib/xrizer"
  #       # OR
  #       #"${pkgs.opencomposite}/lib/opencomposite"
  #       # OR (using nixpkgs-xr)
  #       # "${pkgs.vapor}/lib/VapoR"
  #     ];
  #   };
}
