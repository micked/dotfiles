{ config, pkgs, libs, ... }:

let
  trm = pkgs.writeShellScriptBin "trm" "transmission-remote-gtk $@";

in {
  home.packages = with pkgs; [
    trm
    transmission-remote-gtk
  ];

  home.file = {
    "transmission-cfg" = {
      source = ./configs/transmission-remote-gtk-config.json;
      target = ".config/transmission-remote-gtk/config.json";
    };
  };

}
