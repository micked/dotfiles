{ config, pkgs, libs, ... }:
{
  #home.packages = with pkgs; [
  #  gitAndTools.delta
  #  gitAndTools.gh
  #];
  programs.git = {
    enable = true;
    userName = "Michael Schantz Klausen";
    userEmail = "sch@ntz.nu";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
      push.autoSetupRemote = true;
    };
    lfs.enable = true;
    ignores = [
      ".direnv/"
      ".ipynb_checkpoints/"
      "*.swp"
    ];
  };

}
