{
  pkgs,
  ...
}: let
  clc = pkgs.writeShellScriptBin "clc" "/home/msk/keep/clc21/clcmainwb21";
in {
  home.packages = with pkgs; [
    zotero
    python3Packages.BlinkStick
    pymol

    clc
    jdk11 #For CLC
  ];

  imports = [
    #./vscode.nix
    ./syncthing.nix
  ];

  programs.git.settings.user.email = pkgs.lib.mkForce "msk@evaxion.ai";
}
