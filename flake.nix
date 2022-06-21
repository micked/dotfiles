{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = {self, nixpkgs, home-manager, ... }@inputs:
  let
    homeAtWork = { config, pkgs, ... }: {
      home.homeDirectory = "/home/msk";
      home.username = "msk";
      home.stateVersion = "22.05";
      imports = [ ./modules/common.nix ./modules/work.nix ];
    };
    homeAtHome = { config, pkgs, ... }: {
      home.homeDirectory = "/home/msk";
      home.username = "msk";
      home.stateVersion = "22.05";
      imports = [ ./modules/common.nix ./modules/private.nix ];
    };
  in {

    nixosConfigurations.principle = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./configuration-desktop.nix ];
    };

    nixosConfigurations.burger = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration-laptop.nix
        home-manager.nixosModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.msk = homeAtHome;
        }
      ];
    };

    nixosConfigurations.msk-oblivion = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./configuration-work.nix ];
    };

    nixosConfigurations.msk-oblivion-2 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration-work2.nix
        home-manager.nixosModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.msk = homeAtWork;
        }
      ];
    };

  };
}
