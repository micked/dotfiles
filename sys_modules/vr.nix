{
  pkgs,
  config,
  ...
}: {
  config = {
    environment.systemPackages = with pkgs; [
      slimevr
    ];

    services.udev.packages = with pkgs; [
      slimevr
    ];

    networking.firewall = {
      allowedUDPPorts = [6969];
    };
  };
}
