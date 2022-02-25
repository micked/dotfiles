{ config, pkgs, libs, ... }:
{

  services.dropbox.enable = true;
  services.dropbox.path = "${config.home.homeDirectory}/dropbox";

}
