{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs2305.url = "nixpkgs/nixos-23.05";
    nixpkgs2411.url = "nixpkgs/nixos-24.11";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixgl = {
      url = "github:nix-community/nixGL";
      #inputs.nixpkgs.follows = "nixpkgs";
      flake = false;
    };
  };
  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    homeAtWork = {
      config,
      pkgs,
      ...
    }: {
      home.homeDirectory = "/home/msk";
      home.username = "msk";
      home.stateVersion = "22.05";
      imports = [./modules/common.nix ./modules/work.nix];
    };
    homeAtHome = {
      config,
      pkgs,
      ...
    }: {
      home.homeDirectory = "/home/msk";
      home.username = "msk";
      home.stateVersion = "22.05";
      imports = [./modules/common.nix ./modules/private.nix];
    };
  in {
    nixosConfigurations.burger = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration-laptop.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.msk = homeAtHome;
          home-manager.extraSpecialArgs = {
            pkgs2305 = import inputs.nixpkgs2305 {system = "x86_64-linux";};
          };
        }
      ];
    };

    nixosConfigurations.zentry3 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration-zentry3.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.msk = {
            config,
            pkgs,
            ...
          }: {
            home.homeDirectory = "/home/msk";
            home.username = "msk";
            home.stateVersion = "22.05";
            imports = [./modules/server.nix];
          };
        }
      ];
    };

    nixosConfigurations.msk-oblivion-2 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration-work2.nix
        home-manager.nixosModules.home-manager
        inputs.agenix.nixosModules.default
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.msk = homeAtWork;
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
          environment.systemPackages = [inputs.agenix.packages.x86_64-linux.default];
          age.secrets.oblivion_nixkey.file = ./secrets/oblivion_nixkey.age;
        }
      ];
    };

    nixosConfigurations.msk-80075 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        inputs.agenix.nixosModules.default
        (import ./configuration-work3.nix {inherit inputs;})
        inputs.nixos-hardware.nixosModules.framework-13-7040-amd
        home-manager.nixosModules.home-manager
      ];
    };

    nixosConfigurations.teenyrig = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        #inputs.agenix.nixosModules.default
        (import ./configuration-teenyrig.nix {inherit inputs;})
        home-manager.nixosModules.home-manager
      ];
    };

    # --

    homeConfigurations = let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      glopts =
        {inherit pkgs;}
        // builtins.fromJSON (builtins.readFile ./hm-lime.nvidia-version.json);
      glpkgs = import (inputs.nixgl + "/default.nix") glopts;
      nixgl_packages = {
        nixGLDefault = glpkgs.nixGLDefault;
        nixGLNvidia = glpkgs.nixGLNvidia;
        nixVulkanNvidia = glpkgs.nixVulkanNvidia;
      };
    in {
      evxcompute = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [./hm-evxcompute.nix];
      };

      lime = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          {
            config.nixGL.packages = nixgl_packages;
          }
          ./hm-lime.nix
        ];
        extraSpecialArgs = {
          pkgs2305 = import inputs.nixpkgs2305 {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
        };
      };
    };
  };
}
