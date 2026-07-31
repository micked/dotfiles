{
  nixpkgs,
  jail-nix,
  system,
}: let
  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };
  lib = pkgs.lib;
  jail = (import "${jail-nix}/lib").init pkgs;

  librusty_v8 = pkgs.fetchurl {
    url = "https://github.com/denoland/rusty_v8/releases/download/v147.4.0/librusty_v8_release_${pkgs.stdenv.hostPlatform.rust.rustcTarget}.a.gz";
    hash =
      {
        x86_64-linux = "sha256-Cd3vbFEZKv/wVBExoO+cAPgxhdI5HaqxgDgqOr82rJU=";
        aarch64-linux = "sha256-lMPw/eAFFAT8obaR8opJbXjbgw58+0maBEyxpeOllFU=";
        aarch64-darwin = "sha256-fnR0DD7woOj8DiaKJYYSPpg0D+lDVmjNwSiPrvtzYq4=";
      }
      .${
        pkgs.stdenv.hostPlatform.system
      }
        or (throw "librusty_v8 147.4.0 is not available for ${pkgs.stdenv.hostPlatform.system}");
  };
  codex-acp = pkgs.codex-acp.overrideAttrs (finalAttrs: previousAttrs: {
    version = "0.16.0";
    src = pkgs.fetchFromGitHub {
      owner = "zed-industries";
      repo = "codex-acp";
      tag = "v${finalAttrs.version}";
      hash = "sha256-LeD3nHvRWX4ZgZ3/fVngDcR6/LtaY4eb2M2WmWaymlY=";
    };
    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit (finalAttrs) pname version src;
      hash = "sha256-ea3XyOaSshvv3oD4rm37nE76ABTbSv1y/s7HX2fqNRk=";
    };
    postPatch = "";
    env =
      previousAttrs.env
      // {
        RUSTY_V8_ARCHIVE = librusty_v8;
      };
  });

  agents = {
    codex = codex-acp;
    claude = pkgs.claude-agent-acp;
  };

  fallbackPackages = with pkgs; [
    bashInteractive
    curl
    diffutils
    findutils
    gawk
    git
    gnugrep
    gnused
    gnutar
    gzip
    jq
    nodejs
    procps
    ripgrep
    unzip
    wget
    which
  ];

  fallbackConfig = devShell: combinators:
    with combinators;
      [
        network
        time-zone
        no-new-session
        (add-pkg-deps fallbackPackages)
        (persist-home "coding-agents")
        mount-cwd
        (try-fwd-env "ANTHROPIC_API_KEY")
        (try-fwd-env "CLAUDE_CODE_OAUTH_TOKEN")
        (try-fwd-env "OPENAI_API_KEY")
        (ro-bind "${pkgs.coreutils}/bin/env" "/usr/bin/env")
      ]
      ++ lib.optional (devShell != null) (add-pkg-deps [devShell]);
in
  {
    projectDir ? "",
    projectGitRoot ? "",
    projectGitDir ? "",
    agent,
  }: let
    agentPackage =
      agents.${agent}
      or (throw "Unknown ACP agent '${agent}'; expected 'codex' or 'claude'");
    projectRef =
      if projectDir == ""
      then null
      else
        builtins.flakeRefToString (
          if projectGitRoot == ""
          then {
            type = "path";
            path = projectDir;
          }
          else
            {
              type = "git";
              url = projectGitRoot;
            }
            // lib.optionalAttrs (projectGitDir != "") {
              dir = projectGitDir;
            }
        );
    project =
      if projectRef == null
      then {}
      else builtins.getFlake projectRef;
    devShell =
      lib.attrByPath [
        "devShells"
        system
        "default"
      ]
      null
      project;
    exportedConfig =
      if devShell != null && devShell ? sandboxConfig
      then devShell.sandboxConfig
      else let
        topLevel =
          lib.attrByPath [
            "sandboxConfigs"
            system
            "default"
          ]
          null
          project;
      in
        if topLevel != null
        then topLevel
        else
          lib.attrByPath [
            "lib"
            "sandboxConfigs"
            system
            "default"
          ]
          null
          project;
    configuredPermissions =
      if exportedConfig == null
      then fallbackConfig devShell jail.combinators
      else if builtins.isFunction exportedConfig
      then exportedConfig jail.combinators
      else exportedConfig;
    devShellBridge = with jail.combinators;
      lib.optionals (devShell != null) [
        (add-runtime ''
          if [[ -z "''${ZED_AGENT_DEV_ENV:-}" ]]; then
            echo "ZED_AGENT_DEV_ENV is not set" >&2
            exit 1
          fi
          RUNTIME_ARGS+=(--ro-bind "$ZED_AGENT_DEV_ENV" /tmp/zed-agent-dev-env)
        '')
        (wrap-entry (entry: ''
          set +u
          # shellcheck source=/dev/null
          source /tmp/zed-agent-dev-env
          ${entry}
        ''))
      ];
    jailedAgent = jail "zed-${agent}-acp-sandboxed" agentPackage (
      configuredPermissions ++ devShellBridge
    );
  in
    pkgs.writeShellApplication {
      name = "zed-agent-sandboxed";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.nix
      ];
      text =
        if devShell == null
        then ''
          exec ${lib.getExe jailedAgent} "$@"
        ''
        else ''
          dev_env="$(mktemp --tmpdir zed-agent-dev-env.XXXXXX)"
          trap 'rm -f "$dev_env"' EXIT

          if ! nix print-dev-env --impure --no-write-lock-file ${
            lib.escapeShellArg (projectRef + "#default")
          } > "$dev_env"; then
            echo "Failed to create the default dev-shell environment for ${projectDir}" >&2
            exit 1
          fi

          ZED_AGENT_DEV_ENV="$dev_env" ${lib.getExe jailedAgent} "$@"
        '';
    }
