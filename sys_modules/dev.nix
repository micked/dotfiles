{pkgs, ...}: let
  litetrack-rules = pkgs.runCommand "litetrack-rules" {} ''
    mkdir -p $out/lib/udev/rules.d
    cp ${./60-litetrack-hidraw.rules} $out/lib/udev/rules.d/60-litetrack-hidraw.rules
  '';
  probe-rs-rules = pkgs.runCommand "probe-rs-rules" {} ''
    mkdir -p $out/lib/udev/rules.d
    cp ${./69-probe-rs.rules} $out/lib/udev/rules.d/69-probe-rs.rules
  '';
  picotool-rules = pkgs.runCommand "picotool-rules" {} ''
    mkdir -p $out/lib/udev/rules.d
    install -Dm444 ${pkgs.picotool.src}/udev/60-picotool.rules -t $out/etc/udev/rules.d
  '';
  slogic-rules = pkgs.runCommand "slogic-rules" {} ''
    mkdir -p $out/lib/udev/rules.d
    cp ${./60-sipeed.rules} $out/lib/udev/rules.d/60-sipeed.rules
  '';
  orbbec-rules = (pkgs.writeTextDir "lib/udev/rules.d/70-orbbec.rules" ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="2bc5", ATTR{idProduct}=="0403", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="2bc5", ATTR{idProduct}=="0407", TAG+="uaccess"
  '');
  libsigrok-sipeed = pkgs.libsigrok.overrideAttrs (final: prev: {
    src = pkgs.fetchFromGitHub {
      owner = "sipeed";
      repo = "libsigrok";
      rev = "bf6b346e597d112f48102fe6a7b2318c6d7b49e2";
      hash = "sha256-j0J0A9+aE1S2P02Ly50wIcvf6dZKkfhrMz7GX3gtkZ0=";
    };
  });
  pulseview-sipeed =
    pkgs.pulseview.overrideAttrs
    (final: prev: {
      src = pkgs.fetchFromGitHub {
        owner = "sipeed";
        repo = "pulseview";
        rev = "f8bb77b4782ac997c9a25c51fe85e8ff8201ba10";
        hash = "sha256-MXFcyyUe6s98UYAM4agXOB36g4HHi+ZHKqCnYunvmmE=";
      };
      buildInputs = with pkgs; [
        glib
        boost
        libsigrok-sipeed
        libsigrokdecode
        libserialport
        libzip
        libftdi1
        hidapi
        glibmm_2_4
        python3
        qt5.qtsvg
      ];
    });
in {
  services.udev.packages = [
    probe-rs-rules
    picotool-rules
    slogic-rules
    litetrack-rules
    orbbec-rules
  ];
  users.groups.plugdev = {};
  nixpkgs.config = {
    segger-jlink.acceptLicense = true;
  };

  environment.systemPackages = with pkgs; [
    nrfutil
    pulseview-sipeed
  ];
}
