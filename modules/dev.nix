{
  pkgs,
  ...
}: let
  python = pkgs.python3Packages;

  treeSitterFromGitHub = {
    pname,
    version,
    owner,
    repo,
    rev ? "v${version}",
    hash,
  }:
    python.buildPythonPackage {
      inherit pname version;
      pyproject = true;
      src = pkgs.fetchFromGitHub {
        inherit owner repo rev hash;
      };
      build-system = [python.setuptools];
      dependencies = [python.tree-sitter];
      doCheck = false;
    };

  tree-sitter-typescript = treeSitterFromGitHub {
    pname = "tree-sitter-typescript";
    version = "0.23.2";
    owner = "tree-sitter";
    repo = "tree-sitter-typescript";
    hash = "sha256-CU55+YoFJb6zWbJnbd38B7iEGkhukSVpBN7sli6GkGY=";
  };
  tree-sitter-go = treeSitterFromGitHub {
    pname = "tree-sitter-go";
    version = "0.25.0";
    owner = "tree-sitter";
    repo = "tree-sitter-go";
    hash = "sha256-y7bTET8ypPczPnMVlCaiZuswcA7vFrDOc2jlbfVk5Sk=";
  };
  tree-sitter-java = treeSitterFromGitHub {
    pname = "tree-sitter-java";
    version = "0.23.5";
    owner = "tree-sitter";
    repo = "tree-sitter-java";
    hash = "sha256-OvEO1BLZLjP3jt4gar18kiXderksFKO0WFXDQqGLRIY=";
  };
  tree-sitter-groovy = treeSitterFromGitHub {
    pname = "tree-sitter-groovy";
    version = "0.1.2";
    owner = "amaanq";
    repo = "tree-sitter-groovy";
    hash = "sha256-usgT3dOq5Tg1wet4jCcS47Dn+2psl7dPRjcimjZClBk=";
  };
  tree-sitter-c = treeSitterFromGitHub {
    pname = "tree-sitter-c";
    version = "0.24.2";
    owner = "tree-sitter";
    repo = "tree-sitter-c";
    hash = "sha256-Juuf57GQI7OAP6O03KtSzyKJAoXtGKjyYJ+sTM1A4mU=";
  };
  tree-sitter-cpp = treeSitterFromGitHub {
    pname = "tree-sitter-cpp";
    version = "0.23.4";
    owner = "tree-sitter";
    repo = "tree-sitter-cpp";
    hash = "sha256-tP5Tu747V8QMCEBYwOEmMQUm8OjojpJdlRmjcJTbe2k=";
  };
  tree-sitter-ruby = treeSitterFromGitHub {
    pname = "tree-sitter-ruby";
    version = "0.23.1";
    owner = "tree-sitter";
    repo = "tree-sitter-ruby";
    hash = "sha256-iu3MVJl0Qr/Ba+aOttmEzMiVY6EouGi5wGOx5ofROzA=";
  };
  tree-sitter-kotlin = treeSitterFromGitHub {
    pname = "tree-sitter-kotlin";
    version = "1.1.0";
    owner = "tree-sitter-grammars";
    repo = "tree-sitter-kotlin";
    hash = "sha256-6jjK5rA/lEdsYDboU7wGfzEiRdZo44SrLlcgWci0xa4=";
  };
  tree-sitter-scala = treeSitterFromGitHub {
    pname = "tree-sitter-scala";
    version = "0.26.0";
    owner = "tree-sitter";
    repo = "tree-sitter-scala";
    hash = "sha256-CnTcQFqYp60rGkLVLRHokUwBenqtWV4hw8boFYNRkbw=";
  };
  tree-sitter-php = treeSitterFromGitHub {
    pname = "tree-sitter-php";
    version = "0.24.1";
    owner = "tree-sitter";
    repo = "tree-sitter-php";
    hash = "sha256-SUoWvPnNpgg5QMxbTw7XfXEoxyOkqnNFPnrMZnoiJH0=";
  };
  tree-sitter-swift =
    (treeSitterFromGitHub {
      pname = "tree-sitter-swift";
      version = "0.7.2";
      owner = "alex-pinkus";
      repo = "tree-sitter-swift";
      rev = "0.7.2-with-generated-files";
      hash = "sha256-tG+tM7B6901QP4QyJdf55V38b4XduSU1eb+gaP7BikE=";
    }).overridePythonAttrs (old: {
      postPatch =
        (old.postPatch or "")
        + ''
          substituteInPlace pyproject.toml --replace 'version = "0.0.1"' 'version = "0.7.2"'
        '';
    });
  tree-sitter-lua = treeSitterFromGitHub {
    pname = "tree-sitter-lua";
    version = "0.5.0";
    owner = "tree-sitter-grammars";
    repo = "tree-sitter-lua";
    hash = "sha256-VzaaN5pj7jMAb/u1fyyH6XmLI+yJpsTlkwpLReTlFNY=";
  };
  tree-sitter-zig = treeSitterFromGitHub {
    pname = "tree-sitter-zig";
    version = "1.1.2";
    owner = "tree-sitter-grammars";
    repo = "tree-sitter-zig";
    hash = "sha256-lDMmnmeGr2ti9W692ZqySWObzSUa9vY7f+oHZiE8N+U=";
  };
  tree-sitter-powershell = treeSitterFromGitHub {
    pname = "tree-sitter-powershell";
    version = "0.26.4";
    owner = "airbus-cert";
    repo = "tree-sitter-powershell";
    hash = "sha256-3mOHt5lWEv8G8EmaeXcquVO+Jo3ot2tVG62El3eVMBU=";
  };
  tree-sitter-elixir = treeSitterFromGitHub {
    pname = "tree-sitter-elixir";
    version = "0.3.5";
    owner = "elixir-lang";
    repo = "tree-sitter-elixir";
    hash = "sha256-C5/+t49pcFh45GqLZRjRs/sH8Ej+dklR/brad+snsyQ=";
  };
  tree-sitter-objc = treeSitterFromGitHub {
    pname = "tree-sitter-objc";
    version = "3.0.2";
    owner = "tree-sitter-grammars";
    repo = "tree-sitter-objc";
    hash = "sha256-aK8Cf8F05NzlXnYS47jPjSyouaajsr1H+vRg2aXsPrs=";
  };
  tree-sitter-julia = treeSitterFromGitHub {
    pname = "tree-sitter-julia";
    version = "0.23.1";
    owner = "tree-sitter";
    repo = "tree-sitter-julia";
    hash = "sha256-jwtMgHYSa9/kcsqyEUBrxC+U955zFZHVQ4N4iogiIHY=";
  };
  tree-sitter-verilog = treeSitterFromGitHub {
    pname = "tree-sitter-verilog";
    version = "1.0.3";
    owner = "tree-sitter";
    repo = "tree-sitter-verilog";
    hash = "sha256-SlK33WQhutIeCXAEFpvWbQAwOwMab68WD3LRIqPiaNY=";
  };
  tree-sitter-fortran = treeSitterFromGitHub {
    pname = "tree-sitter-fortran";
    version = "0.6.0";
    owner = "stadelmanma";
    repo = "tree-sitter-fortran";
    hash = "sha256-je9RlV/KozBGcCrOeFLC0f3LZ0avxZIn3nAiHzrWIoI=";
  };

  graphify = python.buildPythonApplication rec {
    pname = "graphifyy";
    version = "0.8.44";
    pyproject = true;
    src = pkgs.fetchFromGitHub {
      owner = "safishamsi";
      repo = "graphify";
      rev = "v${version}";
      hash = "sha256-/xDaBr5jFm7rGKnj1jiUhmX3+WeqHdB06ieiQHgRQsI=";
    };
    build-system = [python.setuptools];
    dependencies = with python; [
      networkx
      numpy
      rapidfuzz
      tree-sitter
      tree-sitter-python
      tree-sitter-javascript
      tree-sitter-typescript
      tree-sitter-go
      tree-sitter-rust
      tree-sitter-java
      tree-sitter-groovy
      tree-sitter-c
      tree-sitter-cpp
      tree-sitter-ruby
      tree-sitter-c-sharp
      tree-sitter-kotlin
      tree-sitter-scala
      tree-sitter-php
      tree-sitter-swift
      tree-sitter-lua
      tree-sitter-zig
      tree-sitter-powershell
      tree-sitter-elixir
      tree-sitter-objc
      tree-sitter-julia
      tree-sitter-verilog
      tree-sitter-fortran
      tree-sitter-bash
      tree-sitter-json
      openai
    ];
    doCheck = false;
  };

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
in {
  home.packages = with pkgs; [
    cursor
    alejandra
    python3
    ripgrep
    graphify
    nil
    nixd
  ];

  programs.zed-editor = {
    package = zed-editor;
    enable = true;
    extensions = ["nix" "toml" "rust"];
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
      agent = {
        sandbox_permissions = {
          write_paths = ["/home/msk/.cache/nix"];
        };
      };
      agent_servers = {
        "Codex (direnv)" = {
          type = "custom";
          command = "direnv";
          args = ["exec" "." "npx" "-y" "@agentclientprotocol/codex-acp"];
          env = {};
        };
        "Claude (direnv)" = {
          type = "custom";
          command = "direnv";
          args = ["exec" "." "npx" "-y" "@agentclientprotocol/claude-agent-acp"];
          env = {};
        };
      };
    };
  };
}
