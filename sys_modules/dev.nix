{pkgs, ...}: let
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
  libsigrok-sipeed = pkgs.libsigrok.overrideAttrs (final: prev: {
    src = pkgs.fetchFromGitHub {
      owner = "sipeed";
      repo = "libsigrok";
      rev = "0ce0720421b6bcc8e65a0c94c5b2883cbfe22d7e";
      hash = "sha256-4aqX+OX4bBsvvb7b1XHKqG6u1Ek3floXDfjr27usZwo=";
    };
  });
  pulseview-sipeed =
    pkgs.pulseview.overrideAttrs
    (final: prev: {
      src = pkgs.fetchFromGitHub {
        owner = "sipeed";
        repo = "pulseview";
        rev = "ed585bc9dfe1dbebb530b668cd10c85064efeb6b";
        hash = "sha256-tOVGT8P6x1WZC94KIAMOR94hOLZog1jjpEecRpFd+wE=";
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
        glibmm
        pcre
        python3
        libsForQt5.qt5.qtsvg
      ];
    });
in {
  services.udev.packages = [
    probe-rs-rules
    picotool-rules
    slogic-rules
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
