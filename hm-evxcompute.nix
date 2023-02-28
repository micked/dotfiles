{ config, pkgs, ... }:
let
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
  micromamba-zsh = pkgs.writeTextFile {
    name = "micromamba.zsh";
    text = ''
      # >>> mamba initialize >>>
      # !! Contents within this block are managed by 'mamba init' !!
      export MAMBA_EXE="${pkgs.micromamba}/bin/micromamba";
      export MAMBA_ROOT_PREFIX="/work/msk/micromamba";
      __mamba_setup="$('${pkgs.micromamba}/bin/micromamba' shell hook --shell zsh --prefix '/work/msk/micromamba' 2> /dev/null)"
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
  nix-load = "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh";
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
    cookiecutter
    zellij
  ];

  imports = [
    ./modules/git.nix
    ./modules/vim.nix
    ./modules/hx.nix
    ./modules/zsh.nix
    ./modules/bash.nix
  ];

  programs.zsh.initExtra = ''
    [[ -f ${nix-load} ]] && source ${nix-load}
    [[ -f ${micromamba-zsh} ]] && source ${micromamba-zsh}
    [[ -f /etc/profile.d/modules.sh ]] && source /etc/profile.d/modules.sh
    path+=('/home/msk/.local/bin')
    export PATH
  '';

  programs.bash.initExtra = ''
    [[ -f ${micromamba-bash} ]] && source ${micromamba-bash}
    [[ -f /etc/profile.d/modules.sh ]] && source /etc/profile.d/modules.sh
  '';

  nixpkgs.config = { allowUnfree = true; };
  home.stateVersion = "22.05";
  programs.home-manager.enable = true;
}
