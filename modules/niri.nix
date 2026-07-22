{
  inputs,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  noctalia = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  imports = [inputs.noctalia.homeModules.default];

  home.sessionVariables.NIXOS_OZONE_WL = "1";

  home.packages = with pkgs; [
    xwayland-satellite
  ];

  # programs.noctalia = {
  #   enable = true;
  #   package = noctalia;
  # };

  xdg.configFile."niri/config.kdl".text = ''
    input {
        keyboard {
            xkb {
                layout "${osConfig.services.xserver.xkb.layout}"
                options "${osConfig.services.xserver.xkb.options}"
            }

            numlock
        }

        touchpad {
            tap
            natural-scroll
        }


    }

    prefer-no-csd

    spawn-at-startup "${lib.getExe noctalia}"

    binds {
        Mod+Return { spawn "${lib.getExe pkgs.kitty}"; }
        Mod+G { spawn "firefox"; }
        Mod+Space { spawn "${lib.getExe noctalia}" "msg" "launcher" "toggle"; }
        Mod+W { close-window; }

        Mod+R hotkey-overlay-title="Run an Application: fuzzel" { spawn "${lib.getExe pkgs.fuzzel}"; }

        Mod+Left  { focus-column-left; }
        Mod+Down  { focus-window-down; }
        Mod+Up    { focus-window-up; }
        Mod+Right { focus-column-right; }

        Mod+Shift+Left  { move-column-left; }
        Mod+Shift+Down  { move-window-down; }
        Mod+Shift+Up    { move-window-up; }
        Mod+Shift+Right { move-column-right; }

        Mod+S { switch-preset-column-width; }
        Mod+Shift+S { switch-preset-column-width-back; }

        Mod+F { maximize-column; }
        Mod+Shift+F { fullscreen-window; }
        Mod+M { maximize-window-to-edges; }

        Mod+WheelScrollDown { focus-workspace-down; }
        Mod+WheelScrollUp   { focus-workspace-up; }

        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+6 { focus-workspace 6; }
        Mod+7 { focus-workspace 7; }
        Mod+8 { focus-workspace 8; }
        Mod+9 { focus-workspace 9; }

        Mod+Shift+1 { move-column-to-workspace 1; }
        Mod+Shift+2 { move-column-to-workspace 2; }
        Mod+Shift+3 { move-column-to-workspace 3; }
        Mod+Shift+4 { move-column-to-workspace 4; }
        Mod+Shift+5 { move-column-to-workspace 5; }
        Mod+Shift+6 { move-column-to-workspace 6; }
        Mod+Shift+7 { move-column-to-workspace 7; }
        Mod+Shift+8 { move-column-to-workspace 8; }
        Mod+Shift+9 { move-column-to-workspace 9; }

        Print { screenshot; }
        Mod+Shift+E { quit; }
    }
  '';

  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 12;
  };

  gtk = {
    enable = true;
    gtk4.theme = null;

    theme = {
      package = pkgs.flat-remix-gtk;
      name = "Flat-Remix-GTK-Grey-Darkest";
    };

    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };

    font = {
      name = "Sans";
      size = 11;
    };
  };
}
