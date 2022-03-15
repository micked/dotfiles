{
  description = "Home manager flake";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
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
            ./modules/vim.nix
            ./modules/zsh.nix
            ./modules/awesomewm.nix
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
            ./modules/work.nix
            ./modules/git.nix
            ./modules/vim.nix
            ./modules/zsh.nix
            ./modules/awesomewm.nix
          ];
        };
      };

    };
  };
}
