{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./git.nix
    ./vim.nix
    ./zsh.nix
  ];
  config = {
    home.packages = with pkgs; [
      firefox
    ];
  };
}
