{pkgs, ...}: let
  blender-mcp = pkgs.callPackage ../packages/blender-mcp.nix {};
  blenderVersion = pkgs.lib.versions.majorMinor pkgs.blender.version;
  skillClient = pkgs.replaceVars ../packages/skills/blender-mcp/scripts/client.py {
    python = pkgs.python3.withPackages (ps: [ps.mcp]);
    server = pkgs.lib.getExe blender-mcp;
  };
in {
  home.packages = [pkgs.blender blender-mcp];

  xdg.configFile."blender/${blenderVersion}/extensions/user_default/mcp".source = "${blender-mcp}/share/blender/extensions/mcp";

  home.file.".agents/skills/blender-mcp/SKILL.md".source = ../packages/skills/blender-mcp/SKILL.md;
  home.file.".agents/skills/blender-mcp/scripts/client.py" = {
    source = skillClient;
    executable = true;
  };
}
