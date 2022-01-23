{
  description = "Home manager flake";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    # neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
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

          # This value determines the Home Manager release that your
          # configuration is compatible with. This helps avoid breakage
          # when a new Home Manager release introduces backwards
          # incompatible changes.
          #
          # You can update Home Manager without changing this value. See
          # the Home Manager release notes for a list of state version
          # changes in each release.

          # Let Home Manager install and manage itself.
          programs.home-manager.enable = true;

          imports = [
            ./modules/git.nix
          # ./modules/kitty.nix
          ];

          # home.packages = with pkgs; [
          # ];
        };
      };
    };
  };
}
