{
  buildNpmPackage,
  fetchFromGitHub,
  lib,
}:
buildNpmPackage rec {
  pname = "codex-acp";
  version = "1.10.0";

  src = fetchFromGitHub {
    owner = "agentclientprotocol";
    repo = "codex-acp";
    tag = "v${version}";
    hash = "sha256-D8uYd30NRXQYUSBFCi66Oq0iRZXpl8P7nWv2m3+KBig=";
  };

  npmDepsHash = "sha256-df1/kPiZFBEq9Um26Qbo9XaYj2J8BOXQmunCQWquDTo=";

  meta = {
    description = "ACP-compatible coding agent powered by Codex";
    homepage = "https://github.com/agentclientprotocol/codex-acp";
    changelog = "https://github.com/agentclientprotocol/codex-acp/releases/tag/v${version}";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
    mainProgram = "codex-acp";
  };
}
