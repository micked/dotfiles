{ config, pkgs, libs, ... }:
{
  home.packages = with pkgs; [
    super-slicer-latest
  ];

  home.file = {
    ".config/SuperSlicer/SuperSlicer.ini".source = ./configs/superslicer/SuperSlicer.ini;
    ".config/SuperSlicer/filament".source = ./configs/superslicer/filament;
    ".config/SuperSlicer/physical_printer".source = ./configs/superslicer/physical_printer;
    ".config/SuperSlicer/print".source = ./configs/superslicer/print;
    ".config/SuperSlicer/printer".source = ./configs/superslicer/printer;
  };
}
