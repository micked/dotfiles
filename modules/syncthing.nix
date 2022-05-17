{ config, pkgs, libs, ... }:
{

  services.syncthing = {
    enable = true;
    tray.enable = true;
  };

}
