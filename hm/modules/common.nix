{ config, pkgs, libs, ... }:

let 
  fx = pkgs.writeShellScriptBin "fx" "firefox $@";
  calc = pkgs.writeShellScriptBin "calc" "gnome-calculator $@";

in {
  home.packages = with pkgs; [
    # my stuff
    fx
    calc

    # other
    sublime4
    firefox
    cinnamon.nemo
    vlc
    pavucontrol
    htop
    inkscape
    teams
    gnome.gnome-calculator
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
