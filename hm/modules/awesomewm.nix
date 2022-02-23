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
      networkmanagerapplet
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

    services.picom = {
      enable = true;
      vSync = true;
      inactiveOpacity = "1.00";
      activeOpacity = "1.00";
      blur = true;
      #experimentalBackends = true;
      backend = "xrender";
      extraOptions = ''
        unredir-if-possible = false;
      '';
      opacityRule = [
        "100:class_g  = 'Firefox'"
        "90:class_g   = 'Alacritty'"
      ];
      fade = false;
      #fadeDelta = 5;
    };
    
    home.file = {
      "awesome" = {
        source = ./awesome/rc.lua;
        target = "./.config/awesome/rc.lua";
      };

      ".config/awesome/lain".source = pkgs.fetchFromGitHub {
         owner = "lcpz";
         repo = "lain";
         rev = "4933d6c";
         sha256 = "NPXsgKcOGp4yDvbv/vouCpDhrEcmXsM2I1IUkDadgjw=";
      };
    };

    xsession = {
      enable = true;
      scriptPath = ".hm-xsession";
      windowManager.awesome = {
        enable = true;
        luaModules = [ pkgs.luaPackages.vicious ];
      };
    };
  }
