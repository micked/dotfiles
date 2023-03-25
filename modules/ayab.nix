{ config, pkgs, libs, ... }:
let
  python = pkgs.python39;

  altgraph = python.pkgs.buildPythonPackage rec {
    pname = "altgraph";
    version = "0.17.3";
    src = python.pkgs.fetchPypi {
      inherit pname version;
      sha256 = "sha256-rTM1gRTffJQWzbj6HqpYUhZsUFEYcXAhxqjHx6u9A90=";
    };
    doCheck = false;
  };

  macholib = python.pkgs.buildPythonPackage rec {
    pname = "macholib";
    version = "1.16.2";
    src = python.pkgs.fetchPypi {
      inherit pname version;
      sha256 = "sha256-VXu/obslXCDpq6/n7WzYBGtI2VJdsvm3fTEipjoqi/g=";
    };
    propagatedBuildInputs = with python.pkgs; [ altgraph ];
    doCheck = false;
  };

  pyinstaller = python.pkgs.buildPythonPackage rec {
    pname = "PyInstaller";
    version = "3.4";
    src = python.pkgs.fetchPypi {
      inherit pname version;
      sha256 = "sha256-pabgSmar/Ph2Homi662TeRnGvjOnuJY+GpYbVcs1mGs=";
    };
    propagatedBuildInputs = with python.pkgs; [
      pefile
      altgraph
      macholib
    ];
    doCheck = false;
  };

  fbs = python.pkgs.buildPythonPackage rec {
    pname = "fbs";
    version = "0.8.6";
    src = python.pkgs.fetchPypi {
      inherit pname version;
      sha256 = "sha256-hIGRJlAtlZBQJ8jGp4j5PzGPHADsFk3eXvBtup0ROc8=";
    };
    propagatedBuildInputs = with python.pkgs; [
      pyinstaller
    ];
    doCheck = false;
  };

  sliplib = python.pkgs.buildPythonPackage rec {
    pname = "sliplib";
    version = "0.4.0";
    src = python.pkgs.fetchPypi {
      inherit pname version;
      sha256 = "sha256-n1Fc6ZOzR6aaTqeEEQsaVoS/h1JT/mrP8ielBzn2Pk4=";
    };
    buildInputs = with python.pkgs; [ sphinx_rtd_theme ];
    doCheck = false;
  };

  #fysom = python.pkgs.buildPythonPackage rec {
  #  pname = "fysom";
  #  version = "2.1.3";
  #  src = python.pkgs.fetchPypi {
  #    inherit pname version;
  #    sha256 = "sha256-7fRMU+OVdH2vPMRViiX9Ed663yIBbkPr1d9xh7P76Ig=";
  #  };
  #  doCheck = false;
  #};

  ayab-python = python.withPackages(ps: with ps; [
    pillow
    pyserial
    sliplib
    #fysom
    playsound
    fbs
    pyqt5
    numpy
    requests
    #wave
    bitarray
    simpleaudio
  ]);
  ayab-desktop = pkgs.stdenv.mkDerivation {
    name = "ayab-desktop";
    src = pkgs.fetchFromGitHub {
      owner = "AllYarnsAreBeautiful";
      repo = "ayab-desktop";
      rev = "e6101bc";
      sha256 = "sha256-wg4fm1fEZvE1d1rmy2BxOkDW4v23mH1uT5PXtbJo8Kg=";
    };

    buildInputs = [ ayab-python ];
    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      mkdir -p $out
      cp -r * $out/
      rm $out/bin/ayab

      cd $out
      pyuic5 src/main/python/ayab/about_gui.ui -o src/main/python/ayab/about_gui.py
      pyuic5 src/main/python/ayab/firmware_flash_gui.ui -o src/main/python/ayab/firmware_flash_gui.py
      pyuic5 src/main/python/ayab/main_gui.ui -o src/main/python/ayab/main_gui.py
      pyuic5 src/main/python/ayab/menu_gui.ui -o src/main/python/ayab/menu_gui.py
      pyuic5 src/main/python/ayab/mirrors_gui.ui -o src/main/python/ayab/mirrors_gui.py
      pyuic5 src/main/python/ayab/prefs_gui.ui -o src/main/python/ayab/prefs_gui.py
      pyuic5 src/main/python/ayab/engine/dock_gui.ui -o src/main/python/ayab/engine/dock_gui.py
      pyuic5 src/main/python/ayab/engine/options_gui.ui -o src/main/python/ayab/engine/options_gui.py
      pyuic5 src/main/python/ayab/engine/status_gui.ui -o src/main/python/ayab/engine/status_gui.py
      pyrcc5 src/main/python/ayab/ayab_logo_rc.qrc -o src/main/python/ayab/ayab_logo_rc.py

      substituteInPlace $out/src/main/python/ayab/ayab.py \
        --replace "logging.basicConfig(filename='ayab_log.txt'," "logging.basicConfig(filename='/dev/null',"

      makeShellWrapper ${ayab-python}/bin/python $out/bin/ayab \
        --set QT_QPA_PLATFORM_PLUGIN_PATH "${pkgs.qt5.qtbase.bin}/lib/qt-${pkgs.qt5.qtbase.version}/plugins" \
        --run "cd $out" \
        --add-flags "-m fbs run"
    '';
  };
in
{

  home.packages = [
    ayab-desktop
  ];

}
