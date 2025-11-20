{
  config,
  pkgs,
  libs,
  ...
}: {
  home.file.".config/zsh/p10k.zsh".source = ./zsh/p10k.zsh;
  home.file.".config/base16-shell".source = pkgs.fetchFromGitHub {
    owner = "chriskempson";
    repo = "base16-shell";
    rev = "ae84047";
    sha256 = "0qy+huAbPypEMkMumDtzcJdQQx5MVgsvgYu4Em/FGpQ=";
  };

  programs.bat.enable = true;

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  programs.zsh = {
    enable = true;
    shellAliases = {
      ls = "ls -1 --color=auto";
      columnt = "column -tns'	'";
      kssh = "kitten ssh";
    };

    dotDir = "${config.xdg.configHome}/zsh";

    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
    };

    completionInit = ''
      autoload -U compinit && compinit -u
      autoload -U +X bashcompinit && bashcompinit
    '';

    initContent = ''
      () { [[ -r $1 ]] && source $1 } "''${XDG_CACHE_HOME:-''$HOME/.cache}/p10k-instant-prompt-''$USERNAME.zsh"

      setopt HIST_IGNORE_DUPS
      setopt HIST_IGNORE_ALL_DUPS
      setopt appendhistory
      setopt incappendhistory
      setopt no_share_history
      unsetopt share_history

      () { [[ -r $1 ]] && source $1 } "$HOME/.config/zsh/.zkbd/$TERM-''${''${DISPLAY:t}:-$VENDOR-$OSTYPE}"

      #zsh-history-substring-search
      bindkey "''${key[Up]}" history-substring-search-up
      bindkey "''${key[Down]}" history-substring-search-down
      bindkey "$terminfo[kcuu1]" history-substring-search-up
      bindkey "$terminfo[kcud1]" history-substring-search-down

      # Base16 Shell
      BASE16_SHELL="$HOME/.config/base16-shell/"
      [ -n "$PS1" ] && \
          [ -s "$BASE16_SHELL/profile_helper.sh" ] && \
              eval "$("$BASE16_SHELL/profile_helper.sh")"

      source ~/.config/zsh/p10k.zsh

      export LESSOPEN="|${pkgs.lesspipe}/bin/lesspipe.sh %s"
    '';

    plugins = [
      {
        name = "zsh-syntax-highlighting";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-syntax-highlighting";
          rev = "5eb677b";
          hash = "sha256-KRsQEDRsJdF7LGOMTZuqfbW6xdV5S38wlgdcCM98Y/Q=";
        };
      }

      {
        name = "zsh-history-substring-search";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-history-substring-search";
          rev = "87ce96b";
          hash = "sha256-1+w0AeVJtu1EK5iNVwk3loenFuIyVlQmlw8TWliHZGI=";
        };
      }

      {
        name = "zsh-autosuggestions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-autosuggestions";
          rev = "0e810e5";
          hash = "sha256-85aw9OM2pQPsWklXjuNOzp9El1MsNb+cIiZQVHUzBnk=";
        };
      }

      {
        name = "powerlevel10k";
        file = "powerlevel10k.zsh-theme";
        src = pkgs.fetchFromGitHub {
          owner = "romkatv";
          repo = "powerlevel10k";
          rev = "v1.20.0";
          hash = "sha256-ES5vJXHjAKw/VHjWs8Au/3R+/aotSbY7PWnWAMzCR8E=";
        };
      }
    ];
  };
}
