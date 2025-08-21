{inputs}: {
  pkgs,
  config,
  ...
}: {
  imports = [
    ./configuration-common.nix
    ./hardware-configuration-teenyrig.nix
  ];

  config = {
    #services.fwupd.enable = true;
    #services.power-profiles-daemon.enable = true;

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    networking.hostName = "teenyrig";
    networking.networkmanager = {
      enable = true;
      plugins = [pkgs.networkmanager-openvpn];
    };

    boot.binfmt.emulatedSystems = ["aarch64-linux"];

    #environment.systemPackages = [inputs.agenix.packages.x86_64-linux.default];
    #age.secrets.oblivion_nixkey.file = ./secrets/oblivion_nixkey.age;
    #age.identityPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    #nix.settings.secret-key-files = [config.age.secrets.oblivion_nixkey.path];

    programs.steam = {
      enable = true;
      #remotePlay.openFirewall = true;
      #dedicatedServer.openFirewall = true;
      #localNetworkGameTransfers.openFirewall = true;
    };

    services.monado = {
      enable = true;
      defaultRuntime = true;
    };

    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-gtk];
      xdgOpenUsePortal = true;
    };

    hardware.graphics = {
      enable = true;
    };

    services.xserver.videoDrivers = ["nvidia"];
    services.xserver.dpi = 96;

    hardware.nvidia = {
      # Modesetting is required.
      modesetting.enable = true;
      # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
      # Enable this if you have graphical corruption issues or application crashes after waking
      # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
      # of just the bare essentials.
      powerManagement.enable = false;
      # Fine-grained power management. Turns off GPU when not in use.
      # Experimental and only works on modern Nvidia GPUs (Turing or newer).
      powerManagement.finegrained = false;
      open = false;
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
        home.stateVersion = "24.11";
        imports = [
          ./modules/common.nix
          ./modules/private.nix
        ];
        services.picom.enable = pkgs.lib.mkForce false;
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

    system.stateVersion = "25.05";
  };
}
