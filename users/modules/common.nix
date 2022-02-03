{ config, pkgs, libs, ... }:
{
  home.packages = with pkgs; [
    sublime4
    firefox
    alacritty
    cinnamon.nemo
    vlc
  ];

  xdg.userDirs = {
    enable = true;
    desktop = "$HOME";
    documents = "$HOME";
    download = "$HOME/downloads";
    music = "$HOME";
    pictures = "$HOME/pictures";
    publicShare = "$HOME/.local/public";
    templates = "$HOME/templates";
    videos = "$HOME";
    createDirectories = true;
  };
}
