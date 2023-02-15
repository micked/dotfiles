{ config, pkgs, libs, ... }:
{

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      conda.symbol = "🐍 ";
      hostname.disabled = true;
      # line_break.disabled = true;
      username.disabled = true;
      custom.load = {
        command = "cat /proc/loadavg | cut -f1 -d ' '";
        when = true;
        symbol = " ";
      };
      directory = {
        truncation_length = 1;
        fish_style_pwd_dir_length = 1;
      };
    };
  };

  programs.bash = {
    enable = true;
    shellAliases = {
       ls="ls -1 --color=auto";
       columnt="column -tns'	'";
    };
    historyControl = [ "ignoredups" ];

    initExtra = ''
      # bind '"\e[A": history-search-backward'
      # bind '"\e[B": history-search-forward'
      # bind '"\e[5~": previous-history'
      # bind '"\e[6~": next-history'
      # Instead, use ble.sh
      source ${pkgs.blesh}/share/blesh/ble.sh

      # Base16 Shell
      BASE16_SHELL="$HOME/.config/base16-shell/"
      [ -n "$PS1" ] && \
          [ -s "$BASE16_SHELL/profile_helper.sh" ] && \
              eval "$("$BASE16_SHELL/profile_helper.sh")"
    '';
  };

}
