{ config, pkgs, libs, ... }:

let
  inkscape-svg2shenzhen = pkgs.fetchzip {
    url = "https://github.com/badgeek/svg2shenzhen/releases/download/0.2.18.7/svg2shenzhen-extension-0.2.18.7.tar.gz";
    sha256 = "KN17dt8X8UqA2zClxICzLyMkMQ8hWuktznMqkuBFGdc=";
    stripRoot=false;
  };
in {
  home.packages = with pkgs; [
    inkscape
    inkscape-svg2shenzhen
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
