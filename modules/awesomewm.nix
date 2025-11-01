{
  config,
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    # Screen Locker
    # i3lock-fancy

    # Theming (GTK)
    # lxappearance
    # arc-icon-theme
    # arc-theme
    # dracula-theme

    # volumeicon
    # solaar
    # psensor

    # screenshot utility
    # scrot
  ];

  services.network-manager-applet.enable = true;

  services.random-background = {
    enable = true;
    interval = "15min";
    imageDirectory = "%h/pictures/backgrounds";
  };

  services.picom = {
    enable = true;
    vSync = true;
    inactiveOpacity = 1.00;
    activeOpacity = 1.00;
    #blur = true;
    #experimentalBackends = true;
    backend = "glx";
    settings = {
      unredir-if-possible = false;
    };
    opacityRules = [
      "100:class_g  = 'Firefox'"
      "90:class_g   = 'Alacritty'"
    ];
    fade = false;
    #fadeDelta = 5;
    #package = config.lib.nixGL.wrap pkgs.picom;
  };

  home.file = {
    "./.config/awesome/rc.lua".source = ./awesome/rc.lua;
    "./.config/awesome/themes/default/theme.lua".source = ./awesome/theme.lua;
    "./.config/awesome/lain".source = pkgs.fetchFromGitHub {
      owner = "lcpz";
      repo = "lain";
      rev = "4933d6c";
      sha256 = "NPXsgKcOGp4yDvbv/vouCpDhrEcmXsM2I1IUkDadgjw=";
    };
  };

  xsession = {
    enable = true;
    scriptPath = ".hm-xsession";
    #windowManager.awesome = {
    #  enable = true;
    #  luaModules = [ pkgs.luaPackages.vicious ];
    #};
  };
}
