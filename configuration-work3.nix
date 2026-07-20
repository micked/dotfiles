{inputs}: {
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [
    ./configuration-common.nix
    ./hardware-configuration-work3.nix
    ./sys_modules/vr.nix
    ./sys_modules/dev.nix
  ];

  config = {
    services.fwupd.enable = true;
    services.power-profiles-daemon.enable = true;

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    networking.hostName = "msk-80075";
    networking.networkmanager = {
      enable = true;
      plugins = [pkgs.networkmanager-openvpn];
    };

    hardware.bluetooth.enable = true;

    services.xserver = {
      displayManager.lightdm.enable = false;
      windowManager.awesome.enable = lib.mkForce false;
    };

    services.pipewire.enable = true;
    programs.niri.enable = true;

    services.greetd = {
      enable = true;
      settings = {
        initial_session = {
          user = "msk";
          command = "${pkgs.niri}/bin/niri-session";
        };

        default_session = {
          user = "greeter";
          command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd ${pkgs.niri}/bin/niri-session";
        };
      };
    };

    security.pam.services.greetd.enableGnomeKeyring = true;
    services.gnome.gnome-keyring.enable = true;

    #boot.binfmt.emulatedSystems = ["aarch64-linux"];
    virtualisation.docker.enable = true;

    environment.systemPackages = [inputs.agenix.packages.x86_64-linux.default];
    age.secrets.oblivion_nixkey.file = ./secrets/oblivion_nixkey.age;
    age.identityPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    nix.settings.secret-key-files = [config.age.secrets.oblivion_nixkey.path];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.msk = {...}: {
        home.homeDirectory = "/home/msk";
        home.username = "msk";
        home.stateVersion = "24.11";
        imports = [
          ./modules/common.nix
          ./modules/work.nix
          ./modules/niri.nix
        ];
      };
      extraSpecialArgs = {
        inherit inputs;
        #pkgs2411 = import inputs.nixpkgs2411 {system = "x86_64-linux";};
        pkgs-stable = import inputs.nixpkgs-stable {system = "x86_64-linux";};
        pkgs2305 = import inputs.nixpkgs2305 {
          system = "x86_64-linux";
          config = {allowUnfree = true;};
        };
      };
    };

    system.stateVersion = "24.11";
  };
}
