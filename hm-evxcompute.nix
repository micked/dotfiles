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
  micromamba-bash = pkgs.writeTextFile {
    name = "micromamba.bash";
    text = ''
      # >>> mamba initialize >>>
      # !! Contents within this block are managed by 'mamba init' !!
      export MAMBA_EXE="${pkgs.micromamba}/bin/micromamba";
      export MAMBA_ROOT_PREFIX="/work/msk/micromamba";
      __mamba_setup="$('${pkgs.micromamba}/bin/micromamba' shell hook --shell bash --prefix '/work/msk/micromamba' 2> /dev/null)"
      if [ $? -eq 0 ]; then
          eval "$__mamba_setup"
      else
          if [ -f "/work/msk/micromamba/etc/profile.d/micromamba.sh" ]; then
              . "/work/msk/micromamba/etc/profile.d/micromamba.sh"
          else
              export  PATH="/work/msk/micromamba/bin:$PATH"  # extra space after export prevents interference from conda init
          fi
      fi
      unset __mamba_setup
      # <<< mamba initialize <<<
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

  home.packages = with pkgs; [
    micromamba
  ];

  imports = [
    ./modules/git.nix
    ./modules/vim.nix
    ./modules/zsh.nix
    ./modules/bash.nix
  ];

  programs.zsh.initExtra = ''
    [[ -f ${conda-zsh} ]] && source ${conda-zsh}
    [[ -f /etc/profile.d/modules.sh ]] && source /etc/profile.d/modules.sh
  '';

  programs.bash.initExtra = ''
    [[ -f ${micromamba-bash} ]] && source ${micromamba-bash}
  '';

  nixpkgs.config = { allowUnfree = true; };
  home.stateVersion = "22.05";
  programs.home-manager.enable = true;
}
