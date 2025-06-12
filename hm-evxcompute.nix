{
  config,
  pkgs,
  lib,
  ...
}: let
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
  jlab = let
    python = pkgs.python3.override {
      packageOverrides = self: super: {
        #numba = super.numba.overridePythonAttrs (prev: {disabled = false;});
        #pynndescent = super.pynndescent.overridePythonAttrs (prev: {doCheck = false;});
        biopython = super.biopython.overrideAttrs {doInstallCheck = false;};
      };
    };
    jupyterlab-vim = python.pkgs.buildPythonPackage rec {
      pname = "jupyterlab-vim";
      version = "4.1.4";
      format = "pyproject";
      src = python.pkgs.fetchPypi {
        pname = "jupyterlab_vim";
        inherit version;
        hash = "sha256-q/KJGq+zLwy5StmDIa5+vL4Mq+Uj042A1WnApQuFIlo=";
      };
      nativeBuildInputs = with python.pkgs; [
        jupyter-packaging
        hatchling
        hatch-nodejs-version
        hatch-jupyter-builder
        jupyterlab
      ];
    };
    pythonEnv = python.withPackages (ps:
      with ps; [
        pandas
        openpyxl
        xlsxwriter
        xlsx2csv
        polars
        tqdm
        scipy
        scikit-learn
        natsort
        requests
        #((umap-learn.override {tensorflow = null;}).overridePythonAttrs (prev: {
        #  nativeCheckInputs = [];
        #  doCheck = false;
        #}))
        matplotlib
        biopython
        nglview
        ipykernel
        jupyterlab
        jupyterlab-vim
        line_profiler
      ]);
  in
    pkgs.stdenvNoCC.mkDerivation rec {
      pname = "jlab";
      version = "1.0";
      dontUnpack = true;
      buildInputs = with pkgs; [makeWrapper nodejs];
      installPhase = ''
        mkdir -p $out/bin/
        makeWrapper ${pythonEnv}/bin/jupyter $out/bin/jlab \
          --add-flags "lab" \
          --append-flags "--app-dir /home/msk/.local/share/jupyter/lab/" \
          --prefix PATH ":" "${pkgs.nodejs}/bin"
        cat > $out/bin/jlab-copy << EOF
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        mkdir -p /home/msk/.local/share/jupyter/lab/
        rm -rf /home/msk/.local/share/jupyter/lab/*
        cp -r ${python.pkgs.jupyterlab}/share/jupyter/lab/* /home/msk/.local/share/jupyter/lab/
        chmod u+w -R /home/msk/.local/share/jupyter/lab/
        EOF
        chmod +x $out/bin/jlab-copy
        ln -s ${pythonEnv}/bin/python $out/bin/globalpy
      '';
    };
in {
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
    jlab
    jq
  ];

  home.activation = {
    jlab-activate = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD echo 'running `jlab-copy`'
      $DRY_RUN_CMD ${jlab}/bin/jlab-copy
    '';
  };

  imports = [
    ./modules/git.nix
    ./modules/vim.nix
    ./modules/hx.nix
    ./modules/zsh.nix
    ./modules/bash.nix
    ./modules/templates.nix
    ./modules/fonts
  ];

  programs.git.userEmail = pkgs.lib.mkForce "msk@evaxion-biotech.com";

  programs.zsh.initExtra = ''
    source ${./modules/slurm-output.sh}
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

  nixpkgs.config = {allowUnfree = true;};
  home.stateVersion = "22.05";
  programs.home-manager.enable = true;
}
