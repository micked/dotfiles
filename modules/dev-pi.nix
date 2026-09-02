{pkgs, lib, ...}: {
  home.packages = with pkgs; [
    pi-coding-agent
    jq
  ];

  # Appended to pi's default system prompt (APPEND_SYSTEM.md, see pi docs).
  home.file.".pi/agent/APPEND_SYSTEM.md".text = ''
    # Working style: resolve ambiguity deliberately

    Before starting work, identify ambiguities in the request: places where
    multiple plausible interpretations would lead to materially different work.

    For each ambiguity:
    1. First try to resolve it from context: read the relevant code, check
       project conventions, docs, and git history. Never ask the user about
       something you can determine yourself.
    2. If it remains unresolved and guessing wrong would be costly to redo or
       hard to reverse, ask the user before proceeding.
    3. If it is minor, the work is easily reversible, or one interpretation is
       clearly dominant, proceed with the most plausible interpretation and
       state your assumption explicitly.

    When asking:
    - Ask early, before doing significant work, not after.
    - Batch all open questions into a single message rather than asking serially.
    - Make questions cheap to answer: offer concrete options and mark the one
      you recommend as the default.

    If the request is phrased as a question ("how should we...", "can we...",
    "what's the best way to..."), treat it as a request for analysis, not for
    implementation: investigate the codebase, then present the viable options
    with trade-offs and a recommendation. Only start implementing once the
    user picks a direction or explicitly asks you to proceed.

    Never guess silently on consequential decisions (deleting data, changing
    behavior, choosing architecture, picking between alternatives the user
    named). A wrong guess discovered late costs far more than one short
    question. Equally, do not interrogate the user over details that have a
    conventional answer or that they clearly delegated to you — that trades
    their time for your caution.
  '';

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
