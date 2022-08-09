{ config, pkgs, ... }:

{
  home.username = "msk";
  home.homeDirectory = "/home/msk";

  imports = [
    ./modules/git.nix
    ./modules/vim.nix
  ];

  nixpkgs.config = { allowUnfree = true; };
  home.stateVersion = "22.05";
  programs.home-manager.enable = true;
}
