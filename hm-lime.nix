{
  config,
  pkgs,
  lib,
  ...
}: let
  nix-load = "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh";
in {
  home.username = "msk";
  home.homeDirectory = "/home/msk";

  nixGL.defaultWrapper = "nvidia";
  programs.kitty.package = (config.lib.nixGL.wrap pkgs.kitty);

  home.packages = with pkgs; [
    xterm
    wget

    #fonts
    dejavu_fonts
    freefont_ttf
    gyre-fonts
    liberation_ttf
    unifont
    noto-fonts-color-emoji
  ];

  imports = [
    ./modules/common.nix
    ./modules/private.nix
    ./modules/awesomewm.nix
    ./modules/vr.nix
  ];

  programs.zsh.initExtra = ''
    [[ -f ${nix-load} ]] && source ${nix-load}
    bindkey "''${key[Home]}" beginning-of-line
    bindkey "''${key[End]}" end-of-line
    bindkey "''${key[Delete]}" delete-char
  '';

  xsession = {
    enable = true;
    scriptPath = lib.mkForce ".xsession";
    windowManager.awesome = {
      enable = true;
      luaModules = [pkgs.luaPackages.vicious];
      #package = (config.lib.nixGL.wrap pkgs.awesome);
    };
    profileExtra = ''
      [[ -f ${nix-load} ]] && source ${nix-load}
      export XDG_DATA_DIRS="/usr/local/share/:/usr/share/:''${XDG_DATA_DIRS}"
    '';
  };

  xresources.properties."Xft.dpi" = 96;

  nixpkgs.config = {allowUnfree = true;};
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
}
