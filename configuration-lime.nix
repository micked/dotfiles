{inputs}: {
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [
    ./configuration-common.nix
    ./hardware-configuration-lime.nix
    ./sys_modules/vr.nix
    ./sys_modules/dev.nix
  ];

  config = {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.kernelPatches = [
      {
        name = "BSB UVC Fix";
        patch = ./sys_modules/0001-Change-device-uvc_version-check-on-dwMaxVideoFrameSi.patch;
      }
    ];

    networking.hostName = "lime";
    networking.networkmanager = {
      enable = true;
      plugins = [pkgs.networkmanager-openvpn];
    };

    services.xserver.xkb.layout = lib.mkForce "us";

    # boot.binfmt.emulatedSystems = ["aarch64-linux"];
    # virtualisation.docker.enable = true;

    networking.firewall.allowedTCPPorts = [9090];

    hardware.bluetooth.enable = true;

    hardware.graphics = {
      enable = true;
    };

    services.xserver.videoDrivers = ["nvidia"];
    services.xserver.dpi = 96;
    services.xserver.displayManager.lightdm.enable = false;

    services.pipewire.enable = true;
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [xdg-desktop-portal-hyprland];
    };

    services.greetd = {
      enable = true;
      settings = {
        initial_session = {
          user = "msk";
          command = "start-hyprland";
        };

        default_session = {
          user = "greeter";
          command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd start-hyprland";
        };
      };
    };

    security.pam.services.greetd.enableGnomeKeyring = true;
    services.gnome.gnome-keyring.enable = true;

    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = true;
      nvidiaSettings = true;
      # package = config.boot.kernelPackages.nvidiaPackages.stable;
      package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
        version = "595.58.03";
        sha256_64bit = "sha256-jA1Plnt5MsSrVxQnKu6BAzkrCnAskq+lVRdtNiBYKfk=";
        sha256_aarch64 = "sha256-hzzIKY1Te8QkCBWR+H5k1FB/HK1UgGhai6cl3wEaPT8=";
        openSha256 = "sha256-6LvJyT0cMXGS290Dh8hd9rc+nYZqBzDIlItOFk8S4n8=";
        settingsSha256 = "sha256-2vLF5Evl2D6tRQJo0uUyY3tpWqjvJQ0/Rpxan3NOD3c=";
        persistencedSha256 = "sha256-AtjM/ml/ngZil8DMYNH+P111ohuk9mWw5t4z7CHjPWw=";
        patchesOpen = [./sys_modules/nvidia-bsb-dsc-fix.patch];
      };
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.msk = {
        config,
        pkgs,
        ...
      }: {
        home.homeDirectory = "/home/msk";
        home.username = "msk";
        home.stateVersion = "25.11";
        imports = [
          ./modules/common.nix
          ./modules/private.nix
          ./modules/vr.nix
          ./modules/hypr.nix
        ];
        #services.picom.enable = pkgs.lib.mkForce false;
        xresources.properties."Xft.dpi" = 96;
        #xdg.configFile = {
        #"openxr/1/active_runtime.json".source = "${pkgs.monado}/share/openxr/1/openxr_monado.json";
        #};
      };
      extraSpecialArgs = {
        pkgs2411 = import inputs.nixpkgs2411 {system = "x86_64-linux";};
        pkgs2305 = import inputs.nixpkgs2305 {
          system = "x86_64-linux";
          config = {allowUnfree = true;};
        };
      };
    };

    #services.autorandr.enable = true;

    system.stateVersion = "25.11";
  };
}
