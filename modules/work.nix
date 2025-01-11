{
  pkgs,
  pkgs2305,
  ...
}: let
  clc = pkgs.writeShellScriptBin "clc" "/home/msk/keep/clc21/clcmainwb21";
in {
  home.packages = with pkgs; [
    zotero
    logseq
    zoom-us
    python3Packages.BlinkStick
    xournal
    pkgs2305.teams

    clc
    jdk11 #For CLC
  ];

  imports = [
    ./vscode.nix
    ./syncthing.nix
  ];

  programs.git.userEmail = pkgs.lib.mkForce "msk@evaxion-biotech.com";
}
