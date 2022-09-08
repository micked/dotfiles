{ config, pkgs, libs, ... }:
{

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      conda.symbol = "🐍 ";
      hostname.disabled = true;
      # line_break.disabled = true;
    };
  };

  programs.bash = {
    enable = true;
    shellAliases = {
       ls="ls -1 --color=auto";
       columnt="column -tns'	'";
    };

    initExtra = ''
      # bind '"\e[A": history-search-backward'
      # bind '"\e[B": history-search-forward'
      # bind '"\e[5~": previous-history'
      # bind '"\e[6~": next-history'
      # Instead, use ble.sh
      source ${pkgs.blesh}/share/ble.sh

      # Base16 Shell
      BASE16_SHELL="$HOME/.config/base16-shell/"
      [ -n "$PS1" ] && \
          [ -s "$BASE16_SHELL/profile_helper.sh" ] && \
              eval "$("$BASE16_SHELL/profile_helper.sh")"
    '';
  };

}
