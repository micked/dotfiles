{ config, pkgs, libs, ... }:
{

programs.vscode = {
  enable = true;
  package = pkgs.vscodium;
  extensions = with pkgs.vscode-extensions; [
    ms-python.python
    ms-toolsai.jupyter
    ms-toolsai.jupyter-renderers
    #ms-vscode-remote.remote-ssh
    vscodevim.vim
  ];
};

}
