{
  config,
  pkgs,
  ...
}: {
  time.timeZone = "Europe/Copenhagen";

  i18n.defaultLocale = "en_IE.UTF-8";
  i18n.extraLocaleSettings.LC_TIME = "en_DK.UTF-8";

  programs.zsh.enable = true;
  users.users.msk = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager" "rfkill" "docker" "dialout"];
    shell = pkgs.zsh;
  };

  #boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  #services.openssh.enable = true;
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  nix = {
    #package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings = {
      trusted-public-keys = [
        "burger:obD5BdMxSJs2sGBeAe5AJX1aF0BQCBSAgIjHKWkT3VY="
        "msk-oblivion:kmf+iO7oFRQ6blNXZrNdMUBn7jxi5cy1lFzLNLRNEEk="
      ];
      secret-key-files = [config.age.secrets.oblivion_nixkey.path];
    };
  };

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "openssl-1.1.1u" #sublime4
    ];
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    home-manager
    chrysalis
  ];

  programs.dconf.enable = true;
  services.gvfs.enable = true;

  services.udev.packages = [pkgs.chrysalis];
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="20a0", ATTR{idProduct}=="41e5", MODE:="0666"
  '';
}
