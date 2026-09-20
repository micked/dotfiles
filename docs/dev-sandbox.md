# Development sandbox

Run commands with the project's default Nix dev-shell environment inside a
jail.nix sandbox. The Home Manager module [`modules/dev.nix`](../modules/dev.nix)
installs `agent-sandbox` and `pibx`; [`modules/dev-sandbox.nix`](../modules/dev-sandbox.nix)
defines the sandbox.

## Run a command

Launch from your project directory:

```sh
cd ~/sync/dev/my-project
pibx

# Run an installed Nix executable, resolving its symlink to the store.
agent-sandbox "$(readlink -f "$(command -v bash)")" -c 'pwd; node --version'
```

The general syntax is:

```text
agent-sandbox [--mount-pi] /nix/store/<store-path>/bin/<command> [arguments...]
```

The executable must exist at that store path. All remaining arguments go to the
command. `--mount-pi` mounts the host's `~/.pi` read-write; `pibx` enables this
option automatically when launching Pi.

The launcher searches upward from the current directory for the nearest
`flake.nix`. If it exports `devShells.${system}.default`, the sandbox loads that
shell's environment. Launch from the project root to
make the whole project available through the default current-directory mount.
Without a default dev shell, the command still runs; fallback permissions apply
unless the flake exports a custom config.

## Default environment

Unless the project supplies a custom sandbox config, the sandbox provides:

- Network access and the host time zone.
- The current directory mounted read-write and a persistent home named
  `coding-agents`.
- Common tools including Bash, Git, Node.js, curl, jq, and ripgrep, plus the
  default dev shell's dependencies when present.
- `ANTHROPIC_API_KEY`, `CLAUDE_CODE_OAUTH_TOKEN`, and `OPENAI_API_KEY` forwarded
  when set on the host.

The selected command's dependencies are included with both default and custom
configs.

## Extra directories

Declare extra mounts on your project's default dev shell:

```nix
devShells.${system}.default = pkgs.mkShell {
  packages = [pkgs.nodejs];
  passthru.sandboxMounts = [
    "~/sync/dev/shared-library"
    "/mnt/datasets"
    "../shared-library"
  ];
};
```

`dev-sandbox` mounts these host directories read-write at the same paths inside
the sandbox, in addition to its existing mounts. No `sandboxConfig` is needed;
the list also applies when a custom sandbox config is present. Directories must
exist. Use quoted strings, not Nix path literals. Relative paths (including `./`
and `../`) resolve from the directory containing the project's `flake.nix`, even
when launching from a subdirectory. Absolute paths and `~/…` strings (expanded
using the launching user's home) also work. Other shell variables are not expanded.

## Custom permissions

Set `passthru.sandboxConfig` on the default dev shell to replace the fallback
permissions. For example, this config keeps network access, a persistent home,
and the current-directory mount, and makes Node.js and Git available:

```nix
devShells.${system}.default = pkgs.mkShell {
  packages = [pkgs.nodejs pkgs.git];
  passthru.sandboxConfig = combinators: with combinators; [
    network
    time-zone
    no-new-session
    (persist-home "coding-agents")
    mount-cwd
    (add-pkg-deps [pkgs.nodejs pkgs.git])
    (try-fwd-env "OPENAI_API_KEY")
    (ro-bind "${pkgs.coreutils}/bin/env" "/usr/bin/env")
  ];
  passthru.sandboxMounts = ["../shared-library"];
};
```

Configs may be lists of jail.nix combinators or functions receiving the
combinators. The first available config wins, in this order:

1. `devShells.${system}.default.sandboxConfig`
2. `sandboxConfigs.${system}.default`
3. `lib.sandboxConfigs.${system}.default`

Extra mounts, the command's dependencies, `--mount-pi`, and dev-shell environment
loading still apply with custom permissions.

## Troubleshooting

- **Usage error:** resolve the executable with `readlink -f`; a command name or
  profile symlink is not a valid executable argument by itself.
- **Missing project files:** launch from the project root, or declare the needed
  directories in `sandboxMounts`.
- **Mount failure:** check that each mount directory exists on the host and that
  relative paths are based on the directory containing `flake.nix`.
- **Dev-shell environment failure:** run
  `nix print-dev-env --impure --no-write-lock-file .#default` from the flake
  directory to inspect the error. In Git projects, new flake files must be
  tracked for Nix to see them.
