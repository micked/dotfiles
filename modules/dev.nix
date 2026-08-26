{
  inputs,
  pkgs,
  ...
}: let
  graphify = pkgs.callPackage ../packages/graphify.nix {};
  codex-acp = pkgs.callPackage ../packages/codex-acp.nix {};
  cursor = pkgs.symlinkJoin {
    name = "cursor";
    paths = [pkgs.code-cursor];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/cursor --set SHELL ${pkgs.zsh}/bin/zsh
    '';
  };
  zed-editor = pkgs.symlinkJoin {
    name = "zed-editor";
    paths = [pkgs.zed-editor];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/zeditor --set GPUI_X11_SCALE_FACTOR 1
    '';
  };
  codex-acp-work = pkgs.symlinkJoin {
    name = "codex-acp-work";
    paths = [codex-acp];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/codex-acp --run 'export CODEX_HOME="$HOME/.codex-work"'
    '';
    meta.mainProgram = "codex-acp";
  };
  nix-format = pkgs.writeShellApplication {
    name = "nix-format";
    runtimeInputs = [
      pkgs.alejandra
      pkgs.coreutils
      pkgs.nix
    ];
    text = ''
      tmp_file="$(mktemp --suffix=.nix)"
      trap 'rm -f "$tmp_file"' EXIT

      cat > "$tmp_file"
      if nix fmt -- "$tmp_file" >/dev/null 2>&1; then
        cat "$tmp_file"
      else
        alejandra --quiet < "$tmp_file"
      fi
    '';
  };
  dev-sandbox-builder = pkgs.writeText "dev-sandbox-builder.nix" ''
    (import ${./dev-sandbox.nix} {
      nixpkgs = ${pkgs.path};
      jail-nix = ${inputs.jail-nix};
      system = ${builtins.toJSON pkgs.stdenv.hostPlatform.system};
    })
  '';
  agent-sandbox = pkgs.writeShellApplication {
    name = "agent-sandbox";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.git
      pkgs.nix
    ];
    text = ''
      command_path="''${1:-}"
      if [[ ! "$command_path" =~ ^/nix/store/[[:alnum:]]{32}-[^/]+/bin/[^/]+$ ]]; then
        echo "Usage: agent-sandbox /nix/store/.../bin/<command> [arguments...]" >&2
        exit 2
      fi
      if [[ ! -x "$command_path" ]]; then
        echo "Command is not executable: $command_path" >&2
        exit 2
      fi
      shift

      project_dir="$PWD"
      while [[ "$project_dir" != "/" && ! -f "$project_dir/flake.nix" ]]; do
        project_dir="$(dirname "$project_dir")"
      done
      if [[ ! -f "$project_dir/flake.nix" ]]; then
        project_dir=""
      fi

      project_git_root=""
      project_git_dir=""
      if [[ -n "$project_dir" ]]; then
        project_git_root="$(
          git -C "$project_dir" rev-parse --show-toplevel 2>/dev/null || true
        )"
        if [[ -n "$project_git_root" ]]; then
          project_git_dir="$(
            git -C "$project_dir" rev-parse --show-prefix
          )"
          project_git_dir="''${project_git_dir%/}"
        fi
      fi

      sandbox="$(
        nix build \
          --impure \
          --no-link \
          --print-out-paths \
          --file ${dev-sandbox-builder} \
          --argstr projectDir "$project_dir" \
          --argstr projectGitRoot "$project_git_root" \
          --argstr projectGitDir "$project_git_dir" \
          --argstr binPath "$command_path"
      )"
      if [[ -z "$sandbox" || "$sandbox" == *$'\n'* ]]; then
        echo "Expected one sandbox output, got: $sandbox" >&2
        exit 1
      fi

      exec "$sandbox/bin/dev-sandbox" "$@"
    '';
  };
in {
  home.packages = with pkgs; [
    cursor
    nix-format
    agent-sandbox
    alejandra
    python3
    ripgrep
    graphify
    nil
    nixd
    #codex-acp
    nodejs
    claude-agent-acp
    cursor-cli
  ];

  programs.zed-editor = {
    package = zed-editor;
    enable = true;
    extensions = [
      "nix"
      "toml"
      "rust"
    ];
    userSettings = {
      theme = {
        mode = "dark";
        dark = "Gruvbox Dark";
        light = "One Light";
      };
      features = {
        copilot = false;
      };
      telemetry = {
        metrics = false;
      };
      hour_format = "hour24";
      load_direnv = "shell_hook";
      format_on_save = "on";
      languages = {
        Nix = {
          format_on_save = "on";
          formatter = {
            external = {
              command = "nix-format";
              arguments = [];
            };
          };
        };
      };
      agent = {
        sandbox_permissions = {
          write_paths = ["/home/msk/.cache/nix"];
        };
      };
      agent_servers = {
        "Codex (sandboxed)" = {
          type = "custom";
          command = "agent-sandbox";
          args = ["${pkgs.lib.getExe codex-acp}"];
          env = {};
        };
        "Codex (Work)" = {
          type = "custom";
          command = "${pkgs.lib.getExe codex-acp-work}";
          args = [];
          env = {};
        };
        "Codex (Work, Sandboxed)" = {
          type = "custom";
          command = "agent-sandbox";
          args = ["${pkgs.lib.getExe codex-acp-work}"];
          env = {};
        };
        "Claude (sandboxed)" = {
          type = "custom";
          command = "agent-sandbox";
          args = ["${pkgs.lib.getExe pkgs.claude-agent-acp}"];
          env = {};
        };
        "Cursor (sandboxed)" = {
          type = "custom";
          command = "agent-sandbox";
          args = [
            "${pkgs.lib.getExe pkgs.cursor-cli}"
            "acp"
          ];
          env = {};
        };
      };
    };
  };
}
