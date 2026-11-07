{inputs}: {pkgs, ...}: let
  monado-git = pkgs.callPackage ../packages/monado-git.nix {
    inherit (inputs) monado-src libsurvive-src;
  };
  patched-bwrap = pkgs.bubblewrap.overrideAttrs (o: {
    patches = (o.patches or []) ++ [./bwrap.patch];
  });
  patched-bwrap-wrapped = pkgs.runCommand "patched-bwrap-wrapped" {nativeBuildInputs = [pkgs.makeBinaryWrapper];} ''
    mkdir -p $out/bin
    makeBinaryWrapper ${patched-bwrap}/bin/bwrap $out/bin/bwrap
  '';
  replace-bwrap-padded = pkgs.writeScriptBin "bwcp" ''
    #!${pkgs.python3}/bin/python
    import sys
    import shutil
    import pathlib

    original = pathlib.Path(sys.argv[2])
    osize = original.stat().st_size
    new = pathlib.Path(sys.argv[1])
    nsize = new.stat().st_size

    padding = osize - nsize
    shutil.copyfile(new, original)
    with open(original, "ba") as f:
        for _ in range(padding):
            f.write(b"\x00")
  '';
  replace-bwrap = pkgs.writeScriptBin "replace-bwrap" ''
    for target in $(find ~/.local/share/Steam/ -type f -name 'srt-bwrap'); do
      ${replace-bwrap-padded}/bin/bwcp ${patched-bwrap-wrapped}/bin/bwrap $target
      chmod u+x $target
    done
  '';
in {
  config = {
    services.monado = {
      enable = false;
      defaultRuntime = false; # Register as default OpenXR runtime
      package = monado-git;
    };

    systemd.user.services.monado.environment = {
      STEAMVR_LH_ENABLE = "1";
      XRT_COMPOSITOR_COMPUTE = "1";
      XRT_COMPOSITOR_FORCE_WAYLAND_DIRECT = "1";
      IPC_EXIT_WHEN_IDLE = "1";
    };

    programs.steam = {
      enable = true;
      package = pkgs.steam.override {
        buildFHSEnv = args: ((pkgs.buildFHSEnv.override {bubblewrap = patched-bwrap;})
          (args // {extraBwrapArgs = (args.extraBwrapArgs or []) ++ ["--cap-add ALL"];}));
        extraProfile = ''
          # Allows Monado/WiVRn to be used
          # export PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1
          # Fixes timezones on VRChat
          unset TZ
        '';
      };
      extraPackages = with pkgs; [
        usbutils
        procps
      ];
    };

    environment.systemPackages = with pkgs; [
      slimevr
      replace-bwrap
    ];

    services.udev = let
      bsb-rules = pkgs.runCommand "bsb-rules" {} ''
        mkdir -p $out/lib/udev/rules.d
        cp ${./60-bigscreen-beyond.rules} $out/lib/udev/rules.d/60-bigscreen-beyond.rules
      '';
    in {
      packages = with pkgs; [
        slimevr
        bsb-rules
      ];
    };

    networking.firewall = {
      allowedUDPPorts = [6969];
    };
  };
}
