{ config, pkgs, libs, ... }:
let
  python = pkgs.python39;
  fbs = python.pkgs.buildPythonPackage rec {
    pname = "fbs";
    version = "0.2.8";
    src = python.pkgs.fetchPypi {
      inherit pname version;
      sha256 = "sha256-ZKO9Jd7/EJCWVxMBNMGFhLriQPjgN1BQst3TIoUW1Wk=";
    };
    doCheck = false;
  };
  sliplib = python.pkgs.buildPythonPackage rec {
    pname = "sliplib";
    version = "0.3.0";
    src = python.pkgs.fetchPypi {
      inherit pname version;
      sha256 = "sha256-3mINsCU1DCas3c72uX5pI0L/rGVET5fa1FTcg2UBdGs=";
    };
    buildInputs = with python.pkgs; [ sphinx_rtd_theme ];
    doCheck = false;
  };
  fysom = python.pkgs.buildPythonPackage rec {
    pname = "fysom";
    version = "2.1.3";
    src = python.pkgs.fetchPypi {
      inherit pname version;
      sha256 = "sha256-7fRMU+OVdH2vPMRViiX9Ed663yIBbkPr1d9xh7P76Ig=";
    };
    doCheck = false;
  };
  ayab-python = python.withPackages(ps: with ps; [
    pillow
    pyserial
    sliplib
    fysom
    playsound
    fbs
    pyqt5

  ]);
  ayab-desktop = pkgs.stdenv.mkDerivation {
    name = "ayab-desktop";
    src = pkgs.fetchFromGitHub {
      owner = "AllYarnsAreBeautiful";
      repo = "ayab-desktop";
      rev = "ab69af7";
      sha256 = "sha256-m7QvFz3pioTcHUREtvlAKTR0c7p9xe8UhmUydBW7fE0=";
    };

    buildInputs = [ ayab-python ];
    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      mkdir -p $out
      cp -r * $out/
      rm $out/bin/ayab
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
