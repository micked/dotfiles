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

  nix = {
    #package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings = {
      auto-optimise-store = true;
      trusted-public-keys = [
        "burger:obD5BdMxSJs2sGBeAe5AJX1aF0BQCBSAgIjHKWkT3VY="
        "msk-oblivion:kmf+iO7oFRQ6blNXZrNdMUBn7jxi5cy1lFzLNLRNEEk="
      ];
    };
  };

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "openssl-1.1.1v" #sublime4
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
