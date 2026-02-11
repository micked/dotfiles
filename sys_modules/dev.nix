{
  pkgs,
  config,
  ...
}: let
  probe-rs-rules = pkgs.runCommand "probe-rs-rules" {} ''
    mkdir -p $out/lib/udev/rules.d
    cp ${./69-probe-rs.rules} $out/lib/udev/rules.d/69-probe-rs.rules
  '';
  picotool-rules = pkgs.runCommand "picotool-rules" {} ''
    mkdir -p $out/lib/udev/rules.d
    install -Dm444 ${pkgs.picotool.src}/udev/60-picotool.rules -t $out/etc/udev/rules.d
  '';
  slogic-rules = pkgs.runCommand "slogic-rules" {} ''
    mkdir -p $out/lib/udev/rules.d
    cp ${./60-sipeed.rules} $out/lib/udev/rules.d/60-sipeed.rules
  '';
in {
  services.udev.packages = [
    probe-rs-rules
    picotool-rules
    slogic-rules
  ];
  users.groups.plugdev = {};
  nixpkgs.config = {
    segger-jlink.acceptLicense = true;
  };

  environment.systemPackages = with pkgs; [
    nrfutil
    pulseview
  ];
}
