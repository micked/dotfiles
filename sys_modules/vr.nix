{
  pkgs,
  config,
  ...
}: let
  patched-bwrap = pkgs.bubblewrap.overrideAttrs (o: {
    patches = (o.patches or []) ++ [./bwrap.patch];
  });
  replace-bwrap = pkgs.writeScriptBin "replace-bwrap" ''
    for target in $(find .local/share/Steam/ -type f -name 'srt-bwrap'); do
      cp -f ${patched-bwrap}/bin/bwrap $target
    done
  '';
in {
  config = {
    programs.steam = {
      enable = true;
      package = pkgs.steam.override {
        buildFHSEnv = args: ((pkgs.buildFHSEnv.override {bubblewrap = patched-bwrap;})
          (args // {extraBwrapArgs = (args.extraBwrapArgs or []) ++ ["--cap-add ALL"];}));
      };
    };

    environment.systemPackages = with pkgs; [
      slimevr
      replace-bwrap
    ];

    services.udev.packages = with pkgs; [
      slimevr
    ];

    networking.firewall = {
      allowedUDPPorts = [6969];
    };
  };
}
