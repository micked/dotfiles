{pkgs}: let
  src = builtins.fetchGit {
    url = "https://github.com/Project-Babble/Baballonia.git";
    rev = "a1d21b01437b79e2659ccc649f01fd9ea4ad0f3b";
    submodules = true;
  };
  dotnet = pkgs.dotnetCorePackages.dotnet_8;
  internal = builtins.fetchurl {
    url = "http://217.154.52.44:7771/builds/trainer/1.0.0.0.zip";
    sha256 = "sha256:0cfc1r1nwcrkihmi9xn4higybyawy465qa6kpls2bjh9wbl5ys82";
  };
in
  pkgs.buildDotnetModule {
    inherit src;
    version = "0.0.0";
    pname = "baballonia";

    buildInputs = with pkgs; [
      cmake
      opencv
      udev
      libjpeg
      libGL
      fontconfig
      xorg.libX11
      xorg.libSM
      xorg.libICE
      (pkgs.callPackage "${src}/nix/opencvsharp.nix" {})
      #onnxruntime
      pkgs.pkgsCuda.onnxruntime
    ];

    runtimeDeps = with pkgs; [
      udev
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      glib
    ];

    dotnetSdk = dotnet.sdk;
    nugetDeps = "${src}/nix/deps.json";
    dotnetRuntime = dotnet.runtime;
    projectFile = "src/Baballonia.Desktop/Baballonia.Desktop.csproj";

    makeWrapperArgs = [
      "--chdir"
      "${placeholder "out"}/lib/baballonia"
    ];

    postUnpack = ''
      cp ${internal} $sourceRoot/src/Baballonia.Desktop/_internal.zip
    '';

    postFixup = ''
      mv $out/bin/Baballonia.Desktop $out/bin/baballonia
      mkdir $out/lib/baballonia/Modules
      ln -s $out/lib/baballonia/*.dll $out/lib/baballonia/Modules/
      ln -s $out/lib/baballonia/libOpenCvSharpExtern.so $out/lib/baballonia/OpenCvSharpExtern.so
    '';
  }
