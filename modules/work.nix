{ config, pkgs, libs, ... }:

let
  clc = pkgs.writeShellScriptBin "clc" "/home/msk/keep/clc21/clcmainwb21";

in {

  home.packages = with pkgs; [
    zotero
    logseq
    zoom-us
    python39Packages.BlinkStick

    clc
    jdk11 #For CLC
  ];

  imports = [
    ./vscode.nix
  ];

  systemd.user.services.maestral = {
    Unit = {
      Description = "Maestral GUI";
      Requires = [ "tray.target" ];
      After = [ "graphical-session-pre.target" "tray.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.maestral-gui}/bin/maestral_qt";
      Restart = "on-failure";
    };

    Install = { WantedBy = [ "graphical-session.target" ]; };
  };

  # services.dropbox.enable = true;
  # services.dropbox.path = "${config.home.homeDirectory}/dropbox";

}
