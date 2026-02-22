{inputs}: {
  pkgs,
  config,
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
      plugins = [ pkgs.networkmanager-openvpn ];
    };

    boot.binfmt.emulatedSystems = ["aarch64-linux"];

    environment.systemPackages = [inputs.agenix.packages.x86_64-linux.default];
    age.secrets.oblivion_nixkey.file = ./secrets/oblivion_nixkey.age;
    age.identityPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    nix.settings.secret-key-files = [config.age.secrets.oblivion_nixkey.path];

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
          ./modules/work.nix
        ];
      };
      extraSpecialArgs = {
        #pkgs2411 = import inputs.nixpkgs2411 {system = "x86_64-linux";};
        pkgs-stable = import inputs.nixpkgs-stable {system = "x86_64-linux";};
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

    services.autorandr.enable = true;

    programs.xss-lock = {
      enable = false;
      lockerCommand = "${pkgs.i3lock-fancy}/bin/i3lock-fancy -p";
    };

    system.stateVersion = "24.11";
  };
}
