{
  pkgs,
  ...
}: {
  imports = [
    ./configuration-common.nix
  ];

  config = {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.msk = {
      config,
      pkgs,
      ...
    }: {
      home.homeDirectory = "/home/msk";
      home.username = "msk";
      home.stateVersion = "24.11";
      imports = [./modules/minimal.nix];
    };
  };
}
