{
  buildNpmPackage,
  fetchFromGitHub,
  lib,
}:
buildNpmPackage rec {
  pname = "codex-acp";
  version = "1.1.7";

  src = fetchFromGitHub {
    owner = "agentclientprotocol";
    repo = "codex-acp";
    tag = "v${version}";
    hash = "sha256-RY1iiajNR3eJI9WYARZnbIHnDl5+gmlPo3GVjJEJ9Zs=";
  };

  npmDepsHash = "sha256-c/sbGziA3Y2mOcPRD3K0PSd8sAVXSQuip8fE/eojl+Y=";

  meta = {
    description = "ACP-compatible coding agent powered by Codex";
    homepage = "https://github.com/agentclientprotocol/codex-acp";
    changelog = "https://github.com/agentclientprotocol/codex-acp/releases/tag/v${version}";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
    mainProgram = "codex-acp";
  };
}
