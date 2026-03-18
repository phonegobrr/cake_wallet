# Headless / TUI / MCP Architecture

## Overview

The Cake Wallet headless stack provides multiple non-Flutter entry points that share a common command/service layer:

- **CLI** (`cake <command>`): One-shot headless commands with optional JSON output
- **TUI** (`cake tui`): Interactive terminal UI with dart_lipgloss styling
- **MCP** (`cake mcp`): JSON-RPC 2.0 server over stdio for AI tool integration
- **Host** (`cake host`): Long-lived API server with HTTP REST + SSE events
- **Watch** (`cake watch`): NDJSON event stream for monitoring/scripting

All surfaces dispatch through the same `CommandBus`, which is populated by `registerAllCommands()` in `packages/cake_headless/lib/bootstrap.dart`.

## Package Structure

```
cw_core/                  # Cross-chain kernel (pure Dart)
  lib/
    register_adapters.dart  # Centralized Hive adapter registration

packages/
  cake_headless/          # Pure-Dart headless core (no Flutter dependency)
    lib/
      commands/           # WalletCommand implementations + CommandBus
      dto/                # Data transfer objects
      events/             # WalletEventBus + WalletEvent
      i18n/               # Headless-safe string resources
      ports/              # Abstract port interfaces
      ports_impl/         # CLI-specific port implementations
      services/           # WalletLock, WalletRuntime
      runtime_context.dart  # Dependency injection context
      bootstrap.dart        # registerAllCommands() + bootstrap()
    tool/
      generate_manifest.dart  # Side-effect-free manifest generator

  cake_console/           # CLI/TUI/MCP/API binary
    bin/cake.dart         # Entry point
    lib/
      api/                # HTTP API server (shelf)
      cli/                # CLI runner, host/watch/manifest commands
      mcp/                # MCP JSON-RPC server
      tui/                # Terminal UI screens and driver
        screens/          # 14 screen implementations

  cake_wallet_headless/   # Bridge package (cw_core-only callbacks)
    lib/
      cake_wallet_headless.dart  # wireHeadlessCallbacks()
```

## Core Constraint: cake_console Must Remain Flutter-Free

`cake_console` must compile with `dart build cli` (or `dart compile exe` on older SDKs) without the Flutter SDK. The bridge package (`cake_wallet_headless`) wires callbacks using only `cw_core` types and Hive boxes.

## Data Flow

```
Entry Point (cake.dart)
  → CakeRuntimeContext (ports + callbacks)
  → bootstrap() → CommandBus (all commands registered)
  → CLI/TUI/MCP/API dispatch through CommandBus
  → Commands use ctx.wallet, ctx.eventBus, etc.
  → WalletEventBus fans out to all transports
```

## Transport Modes

### HTTP API (`cake host`)
- REST: `POST /api/v1/command/<name>` — dispatches through CommandBus
- SSE: `GET /api/v1/events` — Server-Sent Events from WalletEventBus
- Capabilities: `GET /api/v1/capabilities` — command manifest JSON
- Auth: `--auth-token` flag enables Bearer token middleware
- Bind: `127.0.0.1` by default; `--bind 0.0.0.0` for external access

### MCP Server (`cake mcp`)
- Protocol: JSON-RPC 2.0 over stdio
- Version: Negotiated with client (supports `2024-11-05`, `2025-03-26`, `2025-06-18`)
- Reactive: Custom `notifications/cakewallet/wallet_event` from EventBus
- Resources: `cake://wallet/current`, `cake://wallet/current/balance`, `cake://wallet/current/sync`
- Resource subscriptions: `resources/subscribe` + `notifications/resources/updated`
- MCP remote transport: Use Streamable HTTP + optional SSE (not WebSocket)

### Event Streaming (`cake watch`)
- Outputs NDJSON events from WalletEventBus to stdout
- Composable: `cake watch | jq '.data.balance'`
- Events include sequence numbers for ordering

### CLI `--watch` Flag
Read-only commands can be re-executed on each wallet event:
```bash
cake balance --watch --json  # Live balance updates
```

## Dart Lipgloss

The TUI uses `dart_lipgloss` (package name). The local development checkout is at `~/Desktop/working/dark_lipgloss` (note: folder name `dark_lipgloss` vs package name `dart_lipgloss`).

For development, use `packages/cake_console/pubspec_overrides.yaml` (gitignored):

```yaml
dependency_overrides:
  dart_lipgloss:
    path: ~/Desktop/working/dark_lipgloss
```

Never commit absolute path dependencies. The main `pubspec.yaml` keeps the git dependency for CI.

## Command Registry

The command registry (`CommandBus`) is the single source of truth for all surfaces. Each command declares:
- `name`: Dotted name (e.g. `wallet.list`, `send.preview`)
- `description`: Human-readable description
- `args`: Map of `CommandArg` with type, required, defaultValue, choices
- `isSafeForNonInteractive`: Whether it can run without user confirmation
- `isDestructive`: Whether it mutates/deletes data
- `status`: `implemented`, `stub`, or `unsupported`

### Generated Manifest
`cake manifest` outputs a JSON manifest of all commands. The `tool/generate_manifest.dart` script generates manifests without side effects (no lock acquisition, no database).

## Adding a New Feature

1. Create a `WalletCommand<T>` subclass in `packages/cake_headless/lib/commands/`
2. Register it in `_registerCommands()` in `bootstrap.dart`
3. If it needs a runtime callback, add the field to `CakeRuntimeContext`
4. CLI and MCP exposure is automatic (dotted names → CLI subcommands, MCP tools)
5. Add a TUI screen path if applicable
6. Emit `WalletEvent` after successful state changes
7. Update `docs/headless_feature_matrix.md`

## TUI Screens

| # | Screen | Hotkey | Notes |
|---|--------|--------|-------|
| 0 | Dashboard | (default) | Balance, sync, recent transactions |
| 1 | Wallets | w | List/open/delete wallets |
| 2 | Send | s | Preview/confirm two-step flow |
| 3 | Receive | r | Address + QR code |
| 4 | History | h | Transaction list with details |
| 5 | Exchange | e | Swap quote with provider details |
| 6 | Settings | - | View/edit settings |
| 7 | Contacts | c | List/delete contacts |
| 8 | Nodes | n | List/select/delete nodes |
| 9 | Backup | b | Export/import/verify |
| 10 | Coin Control | - | Freeze/unfreeze UTXOs |
| 11 | Tokens | - | Add/remove ERC20/SPL/TRC tokens |
| 12 | Tor | t | Status/enable/disable |
| 13 | Command Palette | : | Fuzzy search all commands |

The Command Palette (`:`) provides TUI access to ALL registered commands without needing dedicated screens.

## Implementation Rules

- Business logic goes in `cake_headless` / bridge, not in TUI/CLI/MCP/API layers
- Command registry + generated capability manifest are canonical
- Keep stdout clean in MCP mode; all debug/log output to stderr
- Host mode owns wallet state/locks; all clients dispatch through shared CommandBus
- Use official MCP lifecycle + transport semantics
- Avoid unrelated app changes; use re-export shims when moving models
- Every new feature must land in shared command/service layer first

## Interactive vs Non-Interactive

| Mode | Interactive? | Notes |
|------|-------------|-------|
| TUI | Yes | Full keyboard input, `capturesInput` screens |
| CLI | No (default) | Pass `--yes` to auto-confirm unsafe commands |
| CLI `--yes` | No + autoConfirm | Unsafe commands execute without prompting |
| MCP | No | `NoOpUserInteraction` throws on confirm; all args via JSON |
| Host | No | Same as MCP for safety |
| No TTY | No | Automatically detected, `NoOpUserInteraction` used |
