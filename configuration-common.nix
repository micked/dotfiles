{ config, pkgs, ... }:

{
  time.timeZone = "Europe/Copenhagen";

  i18n.defaultLocale = "en_IE.UTF-8";
  i18n.extraLocaleSettings.LC_TIME = "en_DK.UTF-8";

  programs.zsh.enable = true;
  users.users.msk = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "rfkill" "docker" "dialout" ];
    shell = pkgs.zsh;
  };

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    home-manager
    autorandr
  ];

  programs.dconf.enable = true;
  services.gvfs.enable = true;

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="20a0", ATTR{idProduct}=="41e5", MODE:="0666"
  '';

}

