{ config, pkgs, libs, ... }:

{
  home.packages = with pkgs; [
    htop
  ];

  imports = [
    ./git.nix
    ./vim.nix
    ./zsh.nix
  ];

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
