{inputs}: {pkgs, ...}: {
  imports = [
    ./configuration-common.nix
    ./hardware-configuration-work3.nix
  ];

  config = {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    networking.hostName = "msk-80075";
    networking.networkmanager.enable = true;

    services.xserver = {
      enable = true;

      xkb = {
        layout = "dk";
        options = "compose:sclk, caps:escape";
      };

      #videoDrivers = ["modesetting"];
      #videoDrivers = [ "intel" ];

      desktopManager.session = [
        {
          name = "home-manager";
          start = ''
            ${pkgs.runtimeShell} $HOME/.hm-xsession &
            waitPID=$!
          '';
        }
      ];
    };

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.msk = {
      config,
      pkgs,
      ...
    }: {
      home.homeDirectory = "/home/msk";
      home.username = "msk";
      home.stateVersion = "24.11";
      imports = [./modules/common.nix];
    };
    home-manager.extraSpecialArgs = {
      pkgs2411 = import inputs.nixpkgs2411 {system = "x86_64-linux";};
      pkgs2305 = import inputs.nixpkgs2305 {
        system = "x86_64-linux";
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            "teams-1.5.00.23861"
          ];
        };
      };
    };

    system.stateVersion = "24.11";
  };
}
