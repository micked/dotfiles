{ config, pkgs, libs, ... }:
{
  home.packages = with pkgs; [
    sublime4
    firefox
    cinnamon.nemo
    vlc
    pavucontrol
    htop
    inkscape
    teams
  ];

  programs.alacritty = {
    enable = true;
    settings = {
      env = {
        WINIT_X11_SCALE_FACTOR = "1";
      };
    };
  };

  xdg.userDirs = {
    enable = true;
    desktop = "$HOME";
    documents = "$HOME/keep";
    download = "$HOME/downloads";
    music = "$HOME";
    pictures = "$HOME/pictures";
    publicShare = "$HOME/.local/public";
    templates = "$HOME/templates";
    videos = "$HOME";
    createDirectories = true;
  };
}
