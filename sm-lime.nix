{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    system-graphics = let
      nvopts =
        {inherit pkgs;}
        // builtins.fromJSON (builtins.readFile ./hm-lime.nvidia-version.json);
    in {
      enable = true;
      package =
        (pkgs.linuxPackages.nvidiaPackages.mkDriver {
          version = nvopts.nvidiaVersion;
          sha256_64bit = nvopts.nvidiaHash;
          sha256_aarch64 = "";
          openSha256 = "";
          settingsSha256 = "";
          persistencedSha256 = "";
        }).override {
          libsOnly = true;
          kernel = null;
        };
    };
    nix = {
      settings = {
        experimental-features = "nix-command flakes";
        auto-optimise-store = true;
        trusted-public-keys = [
          "burger:obD5BdMxSJs2sGBeAe5AJX1aF0BQCBSAgIjHKWkT3VY="
          "msk-oblivion:kmf+iO7oFRQ6blNXZrNdMUBn7jxi5cy1lFzLNLRNEEk="
        ];
        trusted-users = ["msk"];
        build-users-group = "nixbld";
      };
    };
    nixpkgs.config = {
      allowUnfree = true;
    };
  };
}
