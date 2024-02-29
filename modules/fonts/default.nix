{
  config,
  pkgs,
  lib,
  ...
}: let
  poppins = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "poppins-font";
    version = "1";

    #src = pkgs.fetchzip {
    #  url = "file://" + ./Poppins.zip;
    #  hash = "sha256-FAg1xn8Gcbwmuvqtg00000004oTT9nqE+Izeq7ZMVcA=";
    #  stripRoot = false;
    #};
    src = ./Poppins.zip;

    unpackPhase = ''
      ${pkgs.unzip}/bin/unzip $src
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/fonts/poppins
      mv *.ttf $out/share/fonts/poppins

      runHook postInstall
    '';
  };
in {
  fonts.fontconfig.enable = true;

  home.packages = [
    poppins
  ];
}
