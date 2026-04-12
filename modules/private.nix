{
  pkgs,
  ...
}: let
  trm = pkgs.writeShellScriptBin "trm" "${pkgs.transmission-remote-gtk}/bin/transmission-remote-gtk $@";
in {
  home.packages = with pkgs; [
    trm
    kicad
    audacity
    blender
  ];

  imports = [
    ./syncthing.nix
    #./vscode.nix
  ];
}
