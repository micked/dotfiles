{pkgs, ...}: let
  clc = pkgs.writeShellScriptBin "clc" "/home/msk/keep/clc21/clcmainwb21";
  pymol-git = pkgs.pymol.overrideAttrs (oldAttrs: {
    src = pkgs.fetchFromGitHub {
      owner = "schrodinger";
      repo = "pymol-open-source";
      rev = "46530027e68dcda561c2126c8e65be8e3102ccc5";
      hash = "sha256-6+Uuk4qWd/I86I4gCPm8G+1uuozKaB5WMBRtMWC0amE=";
    };
    patches = [(builtins.elemAt oldAttrs.patches 0)];
    disabledTests = oldAttrs.disabledTests ++ ["test_protonate_fallback" "test_protonate_fallback_low_pH"];
  });
in {
  home.packages = with pkgs; [
    zotero
    python3Packages.blinkstick
    pymol-git
    kicad

    clc
    jdk11 #For CLC
  ];

  imports = [
    #./vscode.nix
    ./syncthing.nix
  ];

  programs.git.settings.user.email = pkgs.lib.mkForce "msk@evaxion.ai";
}
