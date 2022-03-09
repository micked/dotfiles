{ config, pkgs, libs, ... }:
{

  home.packages = with pkgs; [
    zotero
  ];

  services.dropbox.enable = true;
  services.dropbox.path = "${config.home.homeDirectory}/dropbox";

}
