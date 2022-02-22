{
  description = "Home manager flake";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
  };
  outputs = {self, ... }@inputs:
  {
    homeConfigurations = {

      nixos = inputs.home-manager.lib.homeManagerConfiguration {
        system = "x86_64-linux";
        homeDirectory = "/home/msk";
        username = "msk";
        stateVersion = "21.11";
        configuration = { config, lib, pkgs, ... }:
        {
          nixpkgs.config = { allowUnfree = true; };
          programs.home-manager.enable = true;

          imports = [
            ./modules/common.nix
            ./modules/private.nix
            ./modules/git.nix
            ./modules/awesomewm.nix
          # ./modules/kitty.nix
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
          nixpkgs.config = { allowUnfree = true; };
          programs.home-manager.enable = true;

          imports = [
            ./modules/common.nix
            ./modules/git.nix
            ./modules/awesomewm.nix
          ];
        };
      };

    };
  };
}
