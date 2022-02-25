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
