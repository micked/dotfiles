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

    services.udev = {
      packages = with pkgs; [
        slimevr
      ];
      extraRules = ''
        # Bigscreen Beyond
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="35bd", ATTRS{idProduct}=="0101", MODE="0660", TAG+="uaccess"
        # Bigscreen Bigeye
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="35bd", ATTRS{idProduct}=="0202", MODE="0660", TAG+="uaccess"
        # Bigscreen Beyond Audio Strap
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="35bd", ATTRS{idProduct}=="0105", MODE="0660", TAG+="uaccess"
        # Bigscreen Beyond Firmware Mode?
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="35bd", ATTRS{idProduct}=="4004", MODE="0660", TAG+="uaccess"
      '';
    };

    networking.firewall = {
      allowedUDPPorts = [6969];
    };
  };
}
