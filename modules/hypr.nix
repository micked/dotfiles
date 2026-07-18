{
  pkgs,
  lib,
  inputs,
  ...
}: let
  inherit (lib.generators) mkLuaInline;

  noctalia = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # hl.bind(keys, dispatcher) - `keys` and `dispatcher` are raw Lua expressions.
  mkBind = keys: dispatcher: {
    _args = [(mkLuaInline keys) (mkLuaInline dispatcher)];
  };

  # hl.bind(keys, dispatcher, { mouse = true }) for interactive mouse binds.
  mkMouseBind = keys: dispatcher: {
    _args = [(mkLuaInline keys) (mkLuaInline dispatcher) {mouse = true;}];
  };

  workspaceBinds = lib.concatMap (
    ws: let
      code = "code:${toString (ws + 9)}";
    in [
      (mkBind ''mod .. " + ${code}"'' ''hl.dsp.focus({ workspace = ${toString ws} })'')
      (mkBind ''mod .. " + SHIFT + ${code}"'' ''hl.dsp.window.move({ workspace = ${toString ws} })'')
    ]
  ) (lib.range 1 9);
in {
  home.sessionVariables.NIXOS_OZONE_WL = "1";

  imports = [inputs.noctalia.homeModules.default];
  programs.noctalia = {
    enable = true;
    package = noctalia;
  };

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    systemd.enable = false;
    settings = {
      mod = {_var = "SUPER";};

      env = {_args = ["WLR_NO_HARDWARE_CURSORS" "1"];};

      bind =
        [
          (mkBind ''mod .. " + R"'' ''hl.dsp.exec_cmd("${pkgs.tofi}/bin/tofi-drun | xargs hyprctl dispatch exec --")'')
          (mkBind ''mod .. " + F"'' ''hl.dsp.exec_cmd("firefox")'')
          (mkBind ''mod .. " + RETURN"'' ''hl.dsp.exec_cmd("kitty")'')
          (mkBind ''mod .. " + W"'' ''hl.dsp.window.close()'')
          (mkBind ''"Print"'' ''hl.dsp.exec_cmd("grimblast copy area")'')
        ]
        ++ workspaceBinds
        ++ [
          (mkMouseBind ''mod .. " + mouse:272"'' ''hl.dsp.window.drag()'')
          (mkMouseBind ''mod .. " + SHIFT + mouse:272"'' ''hl.dsp.window.resize()'')
        ];

      on = {
        _args = [
          "hyprland.start"
          (mkLuaInline ''
            function()
              hl.exec_cmd("${lib.getExe noctalia}")
            end'')
        ];
      };
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
