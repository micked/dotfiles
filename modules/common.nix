{
  config,
  pkgs,
  lib,
  ...
}: let
  fx = pkgs.writeShellScriptBin "fx" "${pkgs.firefox}/bin/firefox $@";
  chr = pkgs.writeShellScriptBin "chr" "${pkgs.chromium}/bin/chromium $@";
  calc = pkgs.writeShellScriptBin "calc" "${pkgs.gnome.gnome-calculator}/bin/gnome-calculator $@";
  c2_pass = pkgs.writeShellScriptBin "c2_pass" ''
    ${pkgs.pass}/bin/pass c2
    ${pkgs.oathToolkit}/bin/oathtool -v --totp=sha256 --digits=8 $(${pkgs.pass}/bin/pass c2_secret) | tail -n1
  '';
  sophos_pass = pkgs.writeShellScriptBin "sophos_pass" ''
    PASS=$(${pkgs.pass}/bin/pass sophos)
    TOKEN=$(${pkgs.oathToolkit}/bin/oathtool --totp=sha1 --digits=6 $(${pkgs.pass}/bin/pass sophos_secret))
    echo $PASS$TOKEN
  '';
  sophos_login = pkgs.writeShellScriptBin "sophos_login" ''
    curl 'https://remote.evaxion-biotech.com:8090/login.xml' \
      -X POST \
      -H 'Content-Type: application/x-www-form-urlencoded' \
      -H 'Origin: https://remote.evaxion-biotech.com:8090' \
      -H 'Referer: https://remote.evaxion-biotech.com:8090/' \
      -H 'Sec-Fetch-Dest: empty' \
      -H 'Sec-Fetch-Mode: cors' \
      -H 'Sec-Fetch-Site: same-origin' \
      --data-raw "mode=191&username=msk&password=$(${sophos_pass}/bin/sophos_pass)&a=1695366061783&producttype=0"
  '';
in {
  home.packages = with pkgs; [
    # my stuff
    fx
    chr
    calc
    c2_pass
    sophos_pass
    sophos_login

    # bluetooth
    blueberry

    # other
    sublime4
    firefox
    cinnamon.nemo-with-extensions
    vlc
    pavucontrol
    htop
    inkscape
    gnome.gnome-calculator
    pass
    libreoffice-fresh
    gnome.file-roller
    evince
    scrot
    gnome.eog
    gimp
    openvpn
    ncdu
    jq

    meslo-lgs-nf
  ];

  imports = [
    ./inkscape.nix
    ./superslicer.nix
    ./git.nix
    ./vim.nix
    ./hx.nix
    ./zsh.nix
    ./awesomewm.nix
  ];

  fonts.fontconfig.enable = true;

  programs.alacritty = {
    enable = true;
    settings = {
      env = {
        WINIT_X11_SCALE_FACTOR = "1";
      };
      font.normal.family = "MesloLGS NF";
    };
  };

  programs.kitty = {
    enable = true;
    font = {
      package = pkgs.meslo-lgs-nf;
      name = "MesloLGS NF";
    };
    settings = {
      enable_audio_bell = "no";
      background_opacity = "0.9";
      include =
        pkgs.fetchFromGitHub {
          owner = "kdrag0n";
          repo = "base16-kitty";
          rev = "fe5862c";
          sha256 = "+pdXnjuYl7E++QvKOrdSokBc32mkYf3e4Gmnn0xS2iQ=";
        }
        + "/colors/base16-gruvbox-dark-pale.conf";
    };
    #theme = "Afterglow";
  };

  xdg = {
    userDirs = {
      enable = true;
      desktop = "$HOME";
      documents = "$HOME/keep";
      download = "$HOME/downloads";
      music = "$HOME";
      pictures = "$HOME/pictures";
      publicShare = "$HOME/.local/public";
      templates = "$HOME/templates";
      videos = "$HOME";
      createDirectories = true;
    };
    mimeApps = {
      enable = true;
      defaultApplications = {
        "application/pdf" = ["org.gnome.Evince.desktop"];
        "image/png" = ["org.gnome.eog.desktop"];
        "image/jpeg" = ["org.gnome.eog.desktop"];
        "image/gif" = ["org.gnome.eog.desktop"];
        "text/plain" = ["sublime_text.desktop"];
      };
    };
  };

  # This is illegal according to the manual
  home.activation = {
    purgeMimeAppsList = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
      $DRY_RUN_CMD rm -rf ~/.config/mimeapps.list
    '';
  };

  services.gpg-agent = {
    enable = true;
    extraConfig = ''
      default-cache-ttl 36000
      max-cache-ttl 36000
    '';
    pinentryFlavor = "tty";
  };
}
