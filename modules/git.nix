{...}: {
  #home.packages = with pkgs; [
  #  gitAndTools.delta
  #  gitAndTools.gh
  #];
  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      pull.rebase = false;
      push.autoSetupRemote = true;
    };
    lfs.enable = true;
    ignores = [
      ".direnv/"
      ".ipynb_checkpoints/"
      "*.swp"
      ".cursor"
    ];
  };
}
