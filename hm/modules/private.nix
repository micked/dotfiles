{ config, pkgs, libs, ... }:
{
  home.packages = with pkgs; [
    transmission-remote-gtk
  ];

  home.file = {
    "transmission-cfg" = {
      source = ./configs/transmission-remote-gtk-config.json;
      target = ".config/transmission-remote-gtk/config.json";
    };
  };

}
