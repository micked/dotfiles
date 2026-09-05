{
  pkgs,
  lib,
  ...
}: let
  pi-coding-editor = pkgs.callPackage ../packages/pi-coding-editor.nix {};
in {
  home.packages = [
    pi-coding-editor
    pkgs.jq
  ];

  # Idempotently add pi-gpt-search to pi's settings.json so pi auto-installs
  # the package on startup. Uses jq to preserve any existing settings.
  home.activation.piGptSearch = lib.hm.dag.entryAfter ["writeBoundary"] ''
    settings_file="$HOME/.pi/agent/settings.json"
    $DRY_RUN_CMD mkdir -p "$(dirname "$settings_file")"

    if [ -f "$settings_file" ]; then
      if ! ${pkgs.jq}/bin/jq -e '.packages // [] | index("git:github.com/mateusdcc/pi-gpt-search")' "$settings_file" >/dev/null 2>&1; then
        $DRY_RUN_CMD ${pkgs.jq}/bin/jq '.packages = ((.packages // []) + ["git:github.com/mateusdcc/pi-gpt-search"])' "$settings_file" > "$settings_file.tmp"
        $DRY_RUN_CMD mv "$settings_file.tmp" "$settings_file"
      fi
    else
      $DRY_RUN_CMD echo '{"packages": ["git:github.com/mateusdcc/pi-gpt-search"]}' > "$settings_file"
    fi
  '';
}
