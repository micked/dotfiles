{ config, pkgs, libs, ... }:

let
  clc = pkgs.writeShellScriptBin "clc" "/home/msk/keep/clc21/clcmainwb21";

in {

  home.packages = with pkgs; [
    zotero
    logseq
    zoom-us
    python39Packages.BlinkStick
    xournal
    teams

    clc
    jdk11 #For CLC
  ];

  imports = [
    ./vscode.nix
    ./syncthing.nix
  ];

}
