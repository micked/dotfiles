{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = {self, nixpkgs, home-manager, ... }@inputs:
  {

    # --

    nixosConfigurations.principle = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./configuration-desktop.nix ];
    };

    nixosConfigurations.burger = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./configuration-laptop.nix ];
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
          home-manager.users.msk = { config, pkgs, ... }:
          {
            home.homeDirectory = "/home/msk";
            home.username = "msk";
            home.stateVersion = "22.05";
            imports = [
              ./modules/common.nix
              ./modules/work.nix
            ];
          };
        }
      ];
    };

    # --

    homeConfigurations = {

      nixos = inputs.home-manager.lib.homeManagerConfiguration {
        system = "x86_64-linux";
        homeDirectory = "/home/msk";
        username = "msk";
        stateVersion = "21.11";
        configuration = { config, lib, pkgs, ... }:
        {
          #nixpkgs.config = { allowUnfree = true; };
          nixpkgs.config.allowUnfreePredicate = (_: true);
          programs.home-manager.enable = true;

          imports = [
            ./modules/common.nix
            ./modules/private.nix
            # ./modules/git.nix
            # ./modules/vim.nix
            # ./modules/zsh.nix
            ./modules/syncthing.nix
            # ./modules/awesomewm.nix
          ];
        };
      };

      work = inputs.home-manager.lib.homeManagerConfiguration {
        system = "x86_64-linux";
        homeDirectory = "/home/msk";
        username = "msk";
        stateVersion = "21.11";
        configuration = { config, lib, pkgs, ... }:
        {
          # nixpkgs.config = { allowUnfree = true; };
          nixpkgs.config.allowUnfreePredicate = (_: true);
          programs.home-manager.enable = true;

          imports = [
            ./modules/common.nix
            ./modules/work.nix
            # ./modules/git.nix
            # ./modules/vim.nix
            # ./modules/zsh.nix
            # ./modules/awesomewm.nix
            # ./modules/vscode.nix
          ];
        };
      };

    };
  };
}
