{ config, pkgs, lib, ... }:
  {
    home.packages = with pkgs; [
      # Screen Locker
      # i3lock-fancy

      # Theming (GTK)
      # lxappearance
      # arc-icon-theme
      # arc-theme
      # dracula-theme

      # system tray (Kind of a hack atm)
      # Need polybar to support this as a first class module
      # gnome3.networkmanagerapplet
      # volumeicon
      # solaar
      # psensor
      # gnome3.nautilus

      # custom scripts
      # custom-script-sysmenu
      # custom-panel-launch
      # custom-browsermediacontrol

      # Required so that BMC can work with chrome
      # plasma-browser-integration

      # file browser
      # ranger
      # screenshot utility
      # scrot
      # image viewer
      # feh
      # Utility to open present directory (Only use it with xmonad to open
      # terminal in same directory)
      # xcwd
    ];

    #services.random-background = {
    #  enable = true;
    #  imageDirectory = "%h/Pictures/backgrounds";
    #};

    #services.picom = {
    #  enable = true;
    #  # inactiveOpacity = "0.55";
    #  # activeOpacity = "0.85";
    #  blur = true;
    #  experimentalBackends = true;
    #  opacityRule = [
    #    "100:class_g   *?= 'Google-chrome'"
    #  ];
    #  extraOptions = ''
    #    # blur-method = "dual_kawase";
    #    # blur-strength = 8;
    #    # corner-radius = 8;
    #    # round-borders = 1;
    #    #
    #    # rounded-corners-exclude = [
    #    #   "class_g = 'Polybar'",
    #    #   "class_g = 'Google-chrome'"
    #    # ];
    #  '';
    #  fade = true;
    #  fadeDelta = 5;
    # };

    xsession = {
      enable = true;
      scriptPath = ".hm-xsession";
      windowManager.awesome = {
        enable = true;
      };
    };
  }
