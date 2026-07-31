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
    binPath,
  }: let
    storePrefix = builtins.storeDir + "/";
    storeRelativePath =
      if lib.hasPrefix storePrefix binPath
      then lib.removePrefix storePrefix binPath
      else throw "Command must be an absolute path below ${builtins.storeDir}: ${binPath}";
    pathComponents = lib.splitString "/" storeRelativePath;
    storePath =
      if
        builtins.length pathComponents
        == 3
        && builtins.elemAt pathComponents 1 == "bin"
        && builtins.elemAt pathComponents 2 != ""
      then builtins.storePath "${storePrefix}${builtins.head pathComponents}"
      else throw "Command must have the form ${builtins.storeDir}/<store-path>/bin/<name>: ${binPath}";
    command = "${storePath}/${lib.concatStringsSep "/" (lib.tail pathComponents)}";
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
    sandboxPermissions = with jail.combinators;
      configuredPermissions
      ++ [
        (add-pkg-deps [storePath])
      ]
      ++ lib.optionals (devShell != null) [
        (add-runtime ''
          if [[ -z "''${DEV_SANDBOX_ENV:-}" ]]; then
            echo "DEV_SANDBOX_ENV is not set" >&2
            exit 1
          fi
          RUNTIME_ARGS+=(--ro-bind "$DEV_SANDBOX_ENV" /tmp/dev-sandbox-env)
        '')
        (wrap-entry (entry: ''
          set +u
          sandbox_path="$PATH"
          # shellcheck source=/dev/null
          source /tmp/dev-sandbox-env
          export PATH="$sandbox_path:$PATH"
          ${entry}
        ''))
      ];
    jailedCommand = jail "dev-sandboxed-command" command sandboxPermissions;
  in
    pkgs.writeShellApplication {
      name = "dev-sandbox";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.nix
      ];
      text =
        if devShell == null
        then ''
          exec ${lib.getExe jailedCommand} "$@"
        ''
        else ''
          dev_env="$(mktemp --tmpdir dev-sandbox-env.XXXXXX)"
          trap 'rm -f "$dev_env"' EXIT

          if ! nix print-dev-env --impure --no-write-lock-file ${
            lib.escapeShellArg (projectRef + "#default")
          } > "$dev_env"; then
            echo "Failed to create the default dev-shell environment for ${projectDir}" >&2
            exit 1
          fi

          DEV_SANDBOX_ENV="$dev_env" ${lib.getExe jailedCommand} "$@"
        '';
    }
