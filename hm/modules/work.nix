{ config, pkgs, libs, ... }:
{

  home.packages = with pkgs; [
    zotero
    logseq
  ];

  services.dropbox.enable = true;
  services.dropbox.path = "${config.home.homeDirectory}/dropbox";

}
