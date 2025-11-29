{
  pkgs,
  config,
  ...
}: let
  probe-rs-rules = pkgs.runCommand "probe-rs-rules" {} ''
    mkdir -p $out/lib/udev/rules.d
    cp ${./69-probe-rs.rules} $out/lib/udev/rules.d/
  '';
  picotool-rules = pkgs.runCommand "picotool-rules" {} ''
    mkdir -p $out/lib/udev/rules.d
    cp ${./69-probe-rs.rules} $out/lib/udev/rules.d/
    install -Dm444 ${pkgs.picotool.src}/udev/60-picotool.rules -t $out/etc/udev/rules.d
  '';
in {
  services.udev.packages = [
    probe-rs-rules
    picotool-rules
  ];
  users.groups.plugdev = {};
}
