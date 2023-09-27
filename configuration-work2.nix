{
  config,
  pkgs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration-work2.nix
    ./configuration-common.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # Setup keyfile
  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
  };

  # Enable swap on luks
  boot.initrd.luks.devices."luks-230fca52-1799-4099-8f23-d472f971583c".device = "/dev/disk/by-uuid/230fca52-1799-4099-8f23-d472f971583c";
  boot.initrd.luks.devices."luks-230fca52-1799-4099-8f23-d472f971583c".keyFile = "/crypto_keyfile.bin";

  boot.kernelParams = ["acpi_backlight=native"];

  age.identityPaths = ["/etc/ssh/ssh_host_ed25519_key"];
  nix.settings.secret-key-files = [config.age.secrets.oblivion_nixkey.path];

  networking.hostName = "msk-oblivion-2"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  console = {
    font = "Lat2-Terminus16";
    keyMap = "dk";
  };

  services.xserver = {
    enable = true;

    layout = "dk";
    xkbOptions = "compose:sclk, caps:escape";

    libinput.enable = true;
    videoDrivers = ["modesetting"];
    #videoDrivers = [ "intel" ];

    desktopManager.session = [
      {
        name = "home-manager";
        start = ''
          ${pkgs.runtimeShell} $HOME/.hm-xsession &
          waitPID=$!
        '';
      }
    ];

    displayManager.autoLogin = {
      enable = true;
      user = "msk";
    };
  };

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override {enableHybridCodec = true;};
  };

  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  virtualisation.docker = {
    enable = true;
    extraPackages = with pkgs; [docker-compose];
    liveRestore = false;
  };

  security.pam.services.lightdm.enableGnomeKeyring = true;
  services.gnome.gnome-keyring.enable = true;

  services.autorandr.enable = true;

  # Enable CUPS to print documents.
  # services.printing.enable = true;
  services.printing.enable = true;
  services.printing.drivers = [pkgs.hplipWithPlugin];
  services.avahi.enable = true;
  services.avahi.openFirewall = true;
  services.ipp-usb.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leavecatenate(variables, "bootdev", bootdev)
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
