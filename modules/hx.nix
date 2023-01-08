{ config, pkgs, libs, ... }:
{
  home.packages = with pkgs; [
    rust-analyzer
  ];

  programs.helix = {
    enable = true;
    settings = {
      theme = "base16";
    };
  };

}
