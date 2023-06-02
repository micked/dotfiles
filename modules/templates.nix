{
  config,
  pkgs,
  libs,
  ...
}: let
  cptpl = pkgs.writeShellScriptBin "cptpl" ''
    DEST="''${2:-.}"
    echo "cp ${./templates}/$1 $DEST"
  '';
  lstpl = pkgs.writeShellScriptBin "lstpl" ''
    ls -1 ${./templates}
  '';
in {
  home.packages = with pkgs; [
    cptpl
    lstpl
  ];
}
