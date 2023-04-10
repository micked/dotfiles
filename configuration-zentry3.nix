# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration-zentry3.nix
      ./configuration-common.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  networking.hostName = "zentry3"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;
  networking.interfaces.enp3s0.ipv4.addresses = [ {
    address = "192.168.0.9";
    prefixLength = 24;
  } ];
  networking.defaultGateway = "192.168.0.1";
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" "8.8.8.8" ];

  # Configure console keymap
  console.keyMap = "dk-latin1";

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    guiAddress = "0.0.0.0:8384";
  };

  networking.firewall = {
    allowedTCPPorts = [ 8384 ];
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.plex = {
    enable = true;
    openFirewall = true;
  };

  systemd.extraConfig = ''
    DefaultTimeoutStopSec=20s
  '';

  services.sonarr = {
    user = "msk";
    enable = true;
    openFirewall = true;
  };

  services.radarr = {
    user = "msk";
    enable = true;
    openFirewall = true;
  };

  services.transmission = {
    user = "msk";
    enable = true;
    openFirewall = true;
    openRPCPort = true;
    settings = {
      download-dir = "/mnt/data/Trnt";
      rpc-username = "msk";
      rpc-whitelist = "127.0.0.1,192.168.0.*";
      rpc-password = "{a0e0ca2b86318e090395cee3913cda88579e922biunK.kTv";
      rpc-bind-address = "0.0.0.0";
      rpc-authentication-required = true;
      incomplete-dir-enabled = false;
      umask = 0;
    };
  };

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };

  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
      intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
    ];
  };

  services.jellyfin = {
    enable = true;
    openFirewall = true;
    group = "users";
  };

  boot.extraModprobeConfig = "options i915 enable_guc=2";
  systemd.services.jellyfin.serviceConfig.PrivateDevices = lib.mkForce false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leavecatenate(variables, "bootdev", bootdev)
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}
