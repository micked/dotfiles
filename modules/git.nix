{ config, pkgs, libs, ... }:
{
  #home.packages = with pkgs; [
  #  gitAndTools.delta
  #  gitAndTools.gh
  #];
  programs.git = {
    enable = true;
    settings = {
      user.name = "Michael Schantz Klausen";
      user.email = "sch@ntz.nu";
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
