{
  lib,
  fetchgit,
  python3Packages,
  fetchFromGitHub,
}:
let
  # Upstream pins mcp<2: 2.x renamed FastMCP to MCPServer. Unmerged ports
  # exist (upstream PRs #43, #47); drop this once one lands.
  mcp = python3Packages.buildPythonPackage rec {
    pname = "mcp";
    version = "1.30.0";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "modelcontextprotocol";
      repo = "python-sdk";
      tag = "v${version}";
      hash = "sha256-EkmTqsK+vBJcURuwFkhtNJMFgtzgw/7Cd+Fpav4P/ko=";
    };

    build-system = with python3Packages; [
      hatchling
      uv-dynamic-versioning
    ];
    dependencies = with python3Packages;
      [
        anyio
        httpx
        httpx-sse
        jsonschema
        pydantic
        pydantic-settings
        pyjwt
        python-multipart
        sse-starlette
        starlette
        typing-extensions
        typing-inspection
        uvicorn
        # cli extra, required by blender-mcp
        python-dotenv
        typer
      ]
      ++ pyjwt.optional-dependencies.crypto;

    # Test suite needs many extra inputs; the import check covers the API
    # blender-mcp uses.
    doCheck = false;
    pythonImportsCheck = ["mcp" "mcp.server.fastmcp"];
  };
in
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
  dependencies = [
    python3Packages.docutils
    mcp
    python3Packages.pyyaml
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
