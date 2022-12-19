{ config, pkgs, libs, ... }:

let
  trm = pkgs.writeShellScriptBin "trm" "${pkgs.transmission-remote-gtk}/bin/transmission-remote-gtk $@";

in {
  home.packages = with pkgs; [
    trm
  ];

  imports = [
    ./syncthing.nix
    ./ayab.nix
    #./vscode.nix
  ];

}
