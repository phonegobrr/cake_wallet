# Headless / TUI / MCP Architecture

## Overview

The Cake Wallet headless stack provides three non-Flutter entry points that share a common command/service layer:

- **CLI** (`cake <command>`): One-shot headless commands with optional JSON output
- **TUI** (`cake tui`): Interactive terminal UI with dart_lipgloss styling
- **MCP** (`cake mcp`): JSON-RPC 2.0 server over stdio for AI tool integration

All three surfaces dispatch through the same `CommandBus`, which is populated by `bootstrap()` in `packages/cake_headless/lib/bootstrap.dart`.

## Package Structure

```
packages/
  cake_headless/    # Pure-Dart headless core (no Flutter dependency)
    lib/
      commands/     # WalletCommand implementations
      dto/          # Data transfer objects
      events/       # WalletEventBus
      i18n/         # Headless-safe string resources
      ports/        # Abstract port interfaces
      ports_impl/   # CLI-specific port implementations
      services/     # WalletLock, WalletRuntime
      runtime_context.dart  # Dependency injection context
      bootstrap.dart        # Command registration + lock acquisition
  cake_console/     # CLI/TUI/MCP binary
    bin/cake.dart   # Entry point
    lib/
      cli/          # CLI runner, output formatting
      mcp/          # MCP JSON-RPC server
      tui/          # Terminal UI screens and driver
```

## Data Flow

```
Entry Point (cake.dart)
  → CakeRuntimeContext (ports + callbacks)
  → bootstrap() → CommandBus (all commands registered)
  → CLI/TUI/MCP dispatch through CommandBus
  → Commands use ctx.wallet, ctx.listWalletInfos, etc.
```

## Key Conventions

### No stdout in MCP mode
MCP mode wraps all execution in `runZoned` with a `ZoneSpecification` that redirects `print()` to stderr. This keeps stdout strictly JSON-RPC.

### Generated CLI subcommands
CLI subcommands are auto-generated from dotted command names. `wallet.list` becomes `cake wallet list`, `nodes.add` becomes `cake nodes add`, etc. This eliminates manual mapping drift.

### isSafeForNonInteractive
Commands that modify state destructively (send, backup, seed display) set `isSafeForNonInteractive = false`. The CommandBus enforces this in non-interactive mode unless `--yes` is passed.

### Screen lifecycle
TUI screens extend `TuiScreen` and use lifecycle hooks (`init`, `refresh`, `onEnter`, `onLeave`) instead of constructor async calls. Screens that capture text input override `capturesInput => true` to prevent global hotkeys from intercepting characters.

## Dart Lipgloss

The TUI uses a local checkout of `dart_lipgloss` at `~/Desktop/working/dart_lipgloss`. For development:

```yaml
# In pubspec_overrides.yaml (not committed):
dependency_overrides:
  dart_lipgloss:
    path: /path/to/dart_lipgloss
```

Do not commit absolute path dependencies.

## Adding a New Feature

1. Create a `WalletCommand<T>` subclass in `packages/cake_headless/lib/commands/`
2. Register it in `bootstrap.dart`
3. If it needs a runtime callback, add the field to `CakeRuntimeContext`
4. CLI and MCP exposure is automatic
5. Add a TUI screen path if applicable
6. Update `docs/headless_feature_matrix.md`

## Implementation Rules

These rules apply to all headless/TUI/MCP development:

- Use `bootstrap.dart` and `docs/headless_feature_matrix.md` as the canonical feature inventory.
- No feature is done until it has shared command implementation, CLI, MCP, and TUI exposure — or an explicit `UNSUPPORTED_ON_PLATFORM` / `INTERACTION_REQUIRED` contract.
- Do not duplicate logic across TUI/CLI/MCP/API; implement once in the shared headless service layer via `CommandBus`.
- During TUI work, use the local dart_lipgloss checkout via `pubspec_overrides.yaml`; never commit an absolute path dependency.
- Prefer official MCP lifecycle/tools/transport semantics when modifying the MCP server.
- Do not leave placeholder success paths — return structured error codes (`SERVICE_UNAVAILABLE`, `UNSUPPORTED_ON_PLATFORM`, `INTERACTION_REQUIRED`).
- Keep stdout protocol-clean in MCP mode. All debug/log output goes to stderr.
- Commands that mutate wallet state must set `isSafeForNonInteractive => false`.
- Use `.toString()` on all command params from MCP (JSON numbers arrive as `int`/`double`, not `String`).
- Asset/native-lib resolution for compiled binaries: use `FilesystemAssetLoader` multi-path search (base, exe-relative, app-dir, cwd).
- `CliPathProvider` delegates to `cw_core/root_dir.dart` for path consistency with the main app.

## Interactive vs Non-Interactive

| Mode | Interactive? | Notes |
|------|-------------|-------|
| TUI | Yes | Full keyboard input, `capturesInput` screens |
| CLI | No (default) | Pass `--yes` to auto-confirm unsafe commands |
| CLI `--yes` | No + autoConfirm | Unsafe commands execute without prompting |
| MCP | No | `NoOpUserInteraction` rejects all prompts; all args via JSON |

## Future Transports

The `CommandBus` is transport-neutral. Planned additions:
- HTTP API server (via `dart:shelf`) — same command dispatch, REST/JSON endpoints
- WebSocket daemon — long-lived process, event streaming via `WalletEventBus`
- MCP reactive notifications — subscribe to `WalletEventBus` for push updates
