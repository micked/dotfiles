{ config, pkgs, libs, ... }:

let 
  fx = pkgs.writeShellScriptBin "fx" "${pkgs.firefox}/bin/firefox $@";
  calc = pkgs.writeShellScriptBin "calc" "${pkgs.gnome.gnome-calculator}/bin/gnome-calculator $@";
  c2_pass = pkgs.writeShellScriptBin "c2_pass" ''
    ${pkgs.pass}/bin/pass c2
    ${pkgs.oathToolkit}/bin/oathtool -v --totp=sha256 --digits=8 $(pass c2_secret) | tail -n1
  '';

in {
  home.packages = with pkgs; [
    # my stuff
    fx
    calc
    c2_pass

    # bluetooth
    blueberry

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
    pass
    libreoffice-fresh
    gnome.file-roller
    evince
    scrot
    gnome.eog
    gimp

    meslo-lgs-nf
  ];

  fonts.fontconfig.enable = true;

  programs.alacritty = {
    enable = true;
    settings = {
      env = {
        WINIT_X11_SCALE_FACTOR = "1";
      };
      font.normal.family = "MesloLGS NF";
    };
  };

  programs.kitty = {
    enable = true;
    font = {
      package = pkgs.meslo-lgs-nf;
      name = "MesloLGS NF";
    };
    settings = {
      enable_audio_bell = "no";
      background_opacity = "0.8";
      include = pkgs.fetchFromGitHub {
        owner = "kdrag0n";
        repo = "base16-kitty";
        rev = "fe5862c";
        sha256 = "+pdXnjuYl7E++QvKOrdSokBc32mkYf3e4Gmnn0xS2iQ=";
      } + "/colors/base16-gruvbox-dark-pale.conf";
    };
    #theme = "Afterglow";
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

  services.gpg-agent = {
    enable = true;
    extraConfig = ''
      default-cache-ttl 36000
      max-cache-ttl 36000
    '';
    pinentryFlavor = "tty";
  };
}
