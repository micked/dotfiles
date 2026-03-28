{pkgs, ...}: {
  home.sessionVariables.NIXOS_OZONE_WL = "1";
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false;
    settings = {
      "$mod" = "SUPER";
      env = [
        "WLR_NO_HARDWARE_CURSORS,1"
      ];
      exec-once = [
        "${pkgs.ashell}/bin/ashell"
      ];
      bind = [
        "$mod, R, exec, tofi-drun | xargs hyprctl dispatch exec --"
        "$mod, F, exec, firefox"
        "$mod, RETURN, exec, kitty"
        ", Print, exec, grimblast copy area"
        "$mod, code:10, workspace, 1"
        "$mod SHIFT, code:10, movetoworkspace, 1"
        "$mod, code:11, workspace, 2"
        "$mod SHIFT, code:11, movetoworkspace, 2"
        "$mod, code:12, workspace, 3"
        "$mod SHIFT, code:12, movetoworkspace, 3"
        "$mod, code:13, workspace, 4"
        "$mod SHIFT, code:13, movetoworkspace, 4"
        "$mod, code:14, workspace, 5"
        "$mod SHIFT, code:14, movetoworkspace, 5"
        "$mod, code:15, workspace, 6"
        "$mod SHIFT, code:15, movetoworkspace, 6"
        "$mod, code:16, workspace, 7"
        "$mod SHIFT, code:16, movetoworkspace, 7"
        "$mod, code:17, workspace, 8"
        "$mod SHIFT, code:17, movetoworkspace, 8"
        "$mod, code:18, workspace, 9"
        "$mod SHIFT, code:18, movetoworkspace, 9"
      ];
    };
  };

  home.pointerCursor = {
    gtk.enable = true;
    # x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 12;
  };

  gtk = {
    enable = true;

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
