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
      # {
      #   name = "BSB DSC Fix";
      #   patch = ./sys_modules/nvidia-bsb-dsc-fix.patch;
      # }
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

    # services.pipewire.enable = true;
    networking.firewall.allowedTCPPorts = [9090];

    hardware.bluetooth.enable = true;

    hardware.graphics = {
      enable = true;
    };

    services.xserver.videoDrivers = ["nvidia"];
    services.xserver.dpi = 96;
    services.xserver.displayManager.lightdm.enable = false;

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
    # programs.regreet.enable = true;
    # systemd.services.greetd.environment = {
    #   WLR_NO_HARDWARE_CURSORS = "1";
    #   GSK_RENDERER = "vulkan";
    #   WLR_RENDERER = "vulkan";
    # };
    # environment = {
    #   variables = {
    #     WLR_NO_HARDWARE_CURSORS = "1";
    #     GSK_RENDERER = "ngl";
    #   };
    # };

    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
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
