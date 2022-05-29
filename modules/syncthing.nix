{ config, pkgs, libs, ... }:
{

  services.syncthing = {
    enable = true;
    tray.enable = true;
    #tray.package = pkgs.qsyncthingtray;
    tray.command = "syncthingtray --wait";
  };

}
