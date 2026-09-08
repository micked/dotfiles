{pkgs, ...}: let
  blender-mcp = pkgs.callPackage ../packages/blender-mcp.nix {};
  blenderVersion = pkgs.lib.versions.majorMinor pkgs.blender.version;
  skillClient = pkgs.replaceVars ../packages/skills/blender-mcp/scripts/client.py {
    python = pkgs.python3.withPackages (ps: [ps.mcp]);
    server = pkgs.lib.getExe blender-mcp;
  };
  skill = pkgs.runCommand "blender-mcp-skill" {} ''
    mkdir -p "$out"
    cp -r ${../packages/skills/blender-mcp}/. "$out/"
    chmod -R u+w "$out"
    install -m755 ${skillClient} "$out/scripts/client.py"
  '';
in {
  home.packages = [pkgs.blender blender-mcp];

  xdg.configFile."blender/${blenderVersion}/extensions/user_default/mcp".source = "${blender-mcp}/share/blender/extensions/mcp";

  home.file.".agents/skills/blender-mcp".source = skill;
}
