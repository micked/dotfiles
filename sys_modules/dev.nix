{
  pkgs,
  config,
  ...
}: let
  probe-rs-rules = pkgs.runCommand "probe-rs-rules" {} ''
    mkdir -p $out/lib/udev/rules.d
    cp ${./69-probe-rs.rules} $out/lib/udev/rules.d/
  '';
in {
  services.udev.packages = [
    probe-rs-rules
  ];
  users.groups.plugdev = {};
}
