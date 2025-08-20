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
      plugins = [ pkgs.networkmanager-openvpn ];
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
