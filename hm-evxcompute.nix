{
  config,
  pkgs,
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
    python = pkgs.python311;
    jupyterlab-vim = python.pkgs.buildPythonPackage rec {
      pname = "jupyterlab-vim";
      version = "0.16.0";
      format = "pyproject";
      src = python.pkgs.fetchPypi {
        pname = "jupyterlab_vim";
        inherit version;
        hash = "sha256-W8o1KmywOzcwt8ZJ3n8N/UPndjCJ2NpWsE+rJyM8AGs=";
      };
      nativeBuildInputs = with python.pkgs; [
        jupyter-packaging
      ];
    };
    pythonEnv = python.withPackages (ps:
      with ps; [
        pandas
        openpyxl
        polars
        tqdm
        scipy
        scikit-learn
        matplotlib
        biopython
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
          mkdir -p /home/msk/.local/share/jupyter/lab/
          rm -rf /home/msk/.local/share/jupyter/lab/*
          cp -r ${python.pkgs.jupyterlab}/share/jupyter/lab/* /home/msk/.local/share/jupyter/lab/
          chmod u+w -R /home/msk/.local/share/jupyter/lab/
        EOF
        chmod +x $out/bin/jlab-copy
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

  imports = [
    ./modules/git.nix
    ./modules/vim.nix
    ./modules/hx.nix
    ./modules/zsh.nix
    ./modules/bash.nix
    ./modules/templates.nix
  ];

  programs.git.userEmail = pkgs.lib.mkForce "msk@evaxion-biotech.com";

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

  nixpkgs.config = {allowUnfree = true;};
  home.stateVersion = "22.05";
  programs.home-manager.enable = true;
}
