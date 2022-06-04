{ config, pkgs, libs, ... }:

let
  inkscape-svg2shenzhen = pkgs.stdenv.mkDerivation {
    version = "0.2.18.7";
    pname = "inkscape-svg2shenzhen";
    src = pkgs.fetchFromGitHub {
      owner = "badgeek";
      repo = "svg2shenzhen";
      rev = "0.2.18.7";
      sha256 = "48U0JgF81C5nQ2qDAM3oM+6oGS4ZavxIsuEI7OnF9bM=";
    };

    nativeBuildInputs = [
      pkgs.boost169
    ];

    installPhase = ''
      mkdir -p $out
      cp -r inkscape/* $out/
      cp bitmap2component $out/svg2shenzhen/bitmap2component_linux64
    '';
  };
in {
  home.packages = with pkgs; [
    inkscape
    cantarell-fonts
  ];

  home.file = {
    "./.config/inkscape/extensions/svg2shenzhen".source = "${inkscape-svg2shenzhen}/svg2shenzhen";
    "./.config/inkscape/extensions/svg2shenzhen_about.inx" = {
      source = "${inkscape-svg2shenzhen}/svg2shenzhen_about.inx";
    };
    "./.config/inkscape/extensions/svg2shenzhen_export.inx" = {
      source = "${inkscape-svg2shenzhen}/svg2shenzhen_export.inx";
    };
    "./.config/inkscape/extensions/svg2shenzhen_prepare.inx" = {
      source = "${inkscape-svg2shenzhen}/svg2shenzhen_prepare.inx";
    };
  };

}
