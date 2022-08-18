{ config, pkgs, ... }:
let
  conda-zsh = pkgs.writeTextFile {
    name = "conda.zsh";
    text = ''
      # >>> conda initialize >>>
      # !! Contents within this block are managed by 'conda init' !!
      __conda_setup="$('/work/msk/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
      if [ $? -eq 0 ]; then
          eval "$__conda_setup"
      else
          if [ -f "/work/msk/miniconda3/etc/profile.d/conda.sh" ]; then
              . "/work/msk/miniconda3/etc/profile.d/conda.sh"
          else
              export PATH="/work/msk/miniconda3/bin:$PATH"
          fi
      fi
      unset __conda_setup
      # <<< conda initialize <<<
    '';
  };
in
{
  home.username = "msk";
  home.homeDirectory = "/home/msk";

  home.file.".hushlogin".source = pkgs.writeTextFile {
    name = "hushlogin";
    text = "";
  };

  imports = [
    ./modules/git.nix
    ./modules/vim.nix
    ./modules/zsh.nix
  ];

  programs.zsh.initExtra = ''
    [[ -f ${conda-zsh} ]] && source ${conda-zsh}
    [[ -f /etc/profile.d/modules.sh ]] && source /etc/profile.d/modules.sh
  '';

  nixpkgs.config = { allowUnfree = true; };
  home.stateVersion = "22.05";
  programs.home-manager.enable = true;
}
