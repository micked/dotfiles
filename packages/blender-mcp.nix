{
  lib,
  fetchgit,
  python3Packages,
}:
python3Packages.buildPythonApplication {
  pname = "blender-mcp";
  version = "1.0.2";
  pyproject = true;

  src = fetchgit {
    url = "https://projects.blender.org/lab/blender_mcp.git";
    rev = "5181fa06d5c601e910eb680a0012d20d1203b8d5";
    hash = "sha256-PjZnKBSls6j6F4r3WK/doofdMDUZO3S573Y8SHCrDqg=";
  };
  postUnpack = ''
    sourceRoot+=/mcp
  '';

  build-system = [python3Packages.setuptools];
  dependencies = with python3Packages; [
    docutils
    mcp
    pyyaml
  ];
  pythonImportsCheck = ["blmcp"];

  # Keep the Blender extension and the server on the same revision.
  postInstall = ''
    mkdir -p $out/share/blender/extensions
    cp -r ../addon/blender_mcp_addon $out/share/blender/extensions/mcp
  '';

  meta = {
    description = "Blender Lab MCP server and Blender extension";
    homepage = "https://projects.blender.org/lab/blender_mcp";
    license = lib.licenses.gpl3Plus;
    mainProgram = "blender-mcp";
  };
}
