{
  config,
  pkgs,
  ...
}: {
  config = {
    services.xserver = {
      enable = true;

      xkb = {
        layout = "dk";
        options = "compose:sclk, caps:escape";
      };

      windowManager.awesome = {
        enable = true;
        luaModules = [pkgs.luaPackages.vicious];
      };
    };

    #programs.nm-applet.enable = true;

    time.timeZone = "Europe/Copenhagen";

    i18n.defaultLocale = "en_IE.UTF-8";
    i18n.extraLocaleSettings.LC_TIME = "en_DK.UTF-8";

    programs.zsh.enable = true;
    users.users.msk = {
      isNormalUser = true;
      extraGroups = ["wheel" "networkmanager" "rfkill" "docker" "dialout" "plugdev"];
      shell = pkgs.zsh;
    };

    console = {
      font = "Lat2-Terminus16";
      keyMap = "dk";
    };

    #boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
    #services.openssh.enable = true;

    nix = {
      extraOptions = ''
        experimental-features = nix-command flakes
      '';
      settings = {
        auto-optimise-store = true;
        trusted-public-keys = [
          "burger:obD5BdMxSJs2sGBeAe5AJX1aF0BQCBSAgIjHKWkT3VY="
          "msk-oblivion:kmf+iO7oFRQ6blNXZrNdMUBn7jxi5cy1lFzLNLRNEEk="
          "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        ];
        substituters = ["https://cache.nixos-cuda.org"];
        trusted-users = ["msk"];
      };
    };

    nixpkgs.config = {
      allowUnfree = true;
      #permittedInsecurePackages = [
      #  "openssl-1.1.1w" #sublime4
      #];
    };

    environment.systemPackages = with pkgs; [
      vim
      wget
      git
      home-manager
      usbutils
      killall
      xkill
      screen
      # chrysalis
    ];

    programs.dconf.enable = true;
    services.gvfs.enable = true;

    home-manager.backupFileExtension = "backup";

    # services.udev.packages = [pkgs.chrysalis];
    # services.udev.extraRules = ''
    #   SUBSYSTEM=="usb", ATTR{idVendor}=="20a0", ATTR{idProduct}=="41e5", MODE:="0666"
    # '';
  };
}
