{ config, pkgs, libs, ... }:

let
  clc = pkgs.writeShellScriptBin "clc" "/home/msk/keep/clc21/clcmainwb21";

in {

  home.packages = with pkgs; [
    zotero
    logseq

    clc
    jdk11 #For CLC
  ];

  services.dropbox.enable = true;
  services.dropbox.path = "${config.home.homeDirectory}/dropbox";

}
