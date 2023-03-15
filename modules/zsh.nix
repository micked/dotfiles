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

  programs.zsh = {
    enable = true;
    shellAliases = {
      ls = "ls -1 --color=auto";
      columnt = "column -tns'	'";
      kssh = "kitty +kitten ssh";
    };

    dotDir = ".config/zsh";

    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
    };

    completionInit = ''
      autoload -U compinit && compinit -u
      autoload -U +X bashcompinit && bashcompinit
    '';

    initExtra = ''
      () { [[ -r $1 ]] && source $1 } "''${XDG_CACHE_HOME:-''$HOME/.cache}/p10k-instant-prompt-''$USERNAME.zsh"

      setopt HIST_IGNORE_DUPS
      setopt HIST_IGNORE_ALL_DUPS
      setopt appendhistory
      setopt incappendhistory
      setopt no_share_history
      unsetopt share_history

      #zsh-history-substring-search
      bindkey "''${key[Up]}" history-substring-search-up
      bindkey "''${key[Down]}" history-substring-search-down

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
          rev = "c5ce001";
          sha256 = "UqeK+xFcKMwdM62syL2xkV8jwkf/NWfubxOTtczWEwA=";
        };
      }

      {
        name = "zsh-history-substring-search";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-history-substring-search";
          rev = "4abed97";
          sha256 = "8kiPBtgsjRDqLWt0xGJ6vBBLqCWEIyFpYfd+s1prHWk=";
        };
      }

      {
        name = "zsh-autosuggestions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-autosuggestions";
          rev = "v0.7.0";
          sha256 = "0z6i9wjjklb4lvr7zjhbphibsyx51psv50gm07mbb0kj9058j6kc";
        };
      }

      {
        name = "powerlevel10k";
        file = "powerlevel10k.zsh-theme";
        src = pkgs.fetchFromGitHub {
          owner = "romkatv";
          repo = "powerlevel10k";
          rev = "v1.16.1";
          sha256 = "DLiKH12oqaaVChRqY0Q5oxVjziZdW/PfnRW1fCSCbjo=";
        };
      }
    ];
  };
}
