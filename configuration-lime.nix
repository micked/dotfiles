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

    networking.hostName = "lime";
    networking.networkmanager = {
      enable = true;
      plugins = [pkgs.networkmanager-openvpn];
    };

    services.xserver.xkb.layout = lib.mkForce "us";

    boot.binfmt.emulatedSystems = ["aarch64-linux"];

    virtualisation.docker.enable = true;

    #xdg.portal = {
    #  enable = true;
    #  extraPortals = [pkgs.xdg-desktop-portal-gtk];
    #  xdgOpenUsePortal = true;
    #};
    networking.firewall.allowedTCPPorts = [9090];

    hardware.bluetooth.enable = true;

    hardware.graphics = {
      enable = true;
    };

    services.xserver.videoDrivers = ["nvidia"];
    services.xserver.dpi = 96;

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

    services.displayManager.autoLogin = {
      enable = true;
      user = "msk";
    };

    security.pam.services.lightdm.enableGnomeKeyring = true;
    services.gnome.gnome-keyring.enable = true;

    #services.autorandr.enable = true;

    system.stateVersion = "25.11";
  };
}
