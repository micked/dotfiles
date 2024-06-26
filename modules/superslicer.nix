{
  config,
  pkgs,
  libs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    #super-slicer-latest
    prusa-slicer
  ];

  home.file = {
    #".config/SuperSlicer/SuperSlicer.ini".source = ./configs/superslicer/SuperSlicer.ini;
    #".config/SuperSlicer/filament".source = ./configs/superslicer/filament;
    #".config/SuperSlicer/physical_printer".source = ./configs/superslicer/physical_printer;
    #".config/SuperSlicer/print".source = ./configs/superslicer/print;
    #".config/SuperSlicer/printer".source = ./configs/superslicer/printer;
    #
    ".config/PrusaSlicer/PrusaSlicer.ini".source = ./configs/prusaslicer/PrusaSlicer.ini;
    ".config/PrusaSlicer/filament".source = ./configs/prusaslicer/filament;
    ".config/PrusaSlicer/physical_printer/3D0.ini".source = ./configs/prusaslicer/physical_printer/3D0.ini;
    ".config/PrusaSlicer/print".source = ./configs/prusaslicer/print;
    ".config/PrusaSlicer/printer".source = ./configs/prusaslicer/printer;
  };

  home.activation = {
    purgeSuperPrusaSlicer = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
      $DRY_RUN_CMD rm -rf ~/.config/SuperSlicer
      $DRY_RUN_CMD rm -rf ~/.config/PrusaSlicer
    '';
  };
}
