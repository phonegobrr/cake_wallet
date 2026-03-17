# Headless Feature Parity Matrix

Track implementation status across all surfaces.

**Legend:** Y = implemented, S = scaffolded (command registered, stub response), P = placeholder UI only, - = not applicable, U = returns UNSUPPORTED_ON_PLATFORM

| Feature | Flutter Desktop | TUI | CLI (headless) | MCP Tool |
|---|---|---|---|---|
| Wallet create | Y | | S | S |
| Wallet restore (seed) | Y | | S | S |
| Wallet restore (keys) | Y | | S | S |
| Wallet list | Y | S | S | S |
| Wallet open/switch | Y | S | S | S |
| Wallet close | Y | | S | S |
| Wallet delete | Y | | S | S |
| Wallet rename | Y | | S | S |
| Wallet seed | Y | | S | S |
| Wallet keys | Y | | S | S |
| Wallet rescan | Y | | S | S |
| Wallet sync start/stop | Y | | S | S |
| Balance display | Y | S | S | S |
| Receive address | Y | S | S | S |
| Receive list addresses | Y | | S | S |
| Receive new subaddress | Y | | S | S |
| Receive rotate | Y | | S | S |
| Receive URI | Y | | S | S |
| Receive label/hide/unhide | Y | | S | S |
| Send transaction | Y | S | S | S |
| Send preview | Y | | S | S |
| Send max | Y | | S | S |
| Send all (sweep) | Y | | S | S |
| Send commit | Y | | S | S |
| Transaction history | Y | S | S | S |
| Transaction details | Y | | S | S |
| Exchange/swap quote | Y | S | S | S |
| Exchange/swap create | Y | | S | S |
| Exchange/swap status | Y | | S | S |
| Exchange providers | Y | | S | S |
| Exchange cancel | Y | | S | S |
| Node list | Y | | S | S |
| Node add | Y | | S | S |
| Node select | Y | | S | S |
| Node delete | Y | | S | S |
| Node edit | Y | | S | S |
| Node test | Y | | S | S |
| Node reset | Y | | S | S |
| Contact list | Y | S | S | S |
| Contact add | Y | | S | S |
| Contact delete | Y | | S | S |
| Contact edit | Y | | S | S |
| Settings list | Y | S | S | S |
| Settings get | Y | | S | S |
| Settings set | Y | | S | S |
| Backup export | Y | | S | S |
| Backup import | Y | | S | S |
| Backup verify | Y | | S | S |
| Sync status | Y | S | S | S |
| Tor status | Y | | S | S |
| Tor enable/disable | Y | | S | S |
| Coin control (list/freeze/unfreeze) | Y | | S | S |
| Token management (list/add/remove) | Y | | S | S |
| Fiat conversion | Y | | S | S |
| Sign/verify message | Y | | U | U |
| Buy/sell (fiat on-ramp) | Y | | U | U |
| Cake Pay | Y | | U | U |
| Hardware wallets | Y | | U | U |
| Payjoin | Y | | - | - |
| WalletConnect | Y | | - | - |

**S** = Command registered in command bus with real or stub response. CLI subcommand wired. MCP tool auto-exposed via command bus introspection. TUI screen dispatches through command bus.

**U** = Command returns `UNSUPPORTED_ON_PLATFORM` error with a structured response, rather than silently omitting the feature.

A feature is **not complete** until:
1. Shared command/service implementation exists in `cake_headless`
2. CLI exposure exists (auto-generated from command bus)
3. MCP exposure exists (auto-generated from command bus)
4. TUI path exists
5. Tests pass

Or it has an explicit `UNSUPPORTED_ON_PLATFORM` / `INTERACTION_REQUIRED` contract.

## Architecture Notes

- **Command Bus**: All headless commands are registered in `packages/cake_headless/lib/bootstrap.dart`. Each registered command is automatically available as a CLI subcommand and MCP tool.
- **MCP Server**: `cake mcp` starts a JSON-RPC 2.0 server over stdio. Introspects the command bus to expose all registered commands as MCP tools. stdout is protocol-clean via `runZoned`.
- **TUI**: `cake tui` (or just `cake` with no args in a terminal) launches the interactive terminal UI with dart_lipgloss styling.
- **CLI**: `cake <command> [subcommand] [--json]` runs headless commands with optional JSON output. Subcommands are auto-generated from dotted command names.
- **WalletRuntime**: Bridge between `CakeRuntimeContext` and GetIt DI container. Wires callback slots after `initializeHeadless()`.
- **No-stdout rule**: In MCP mode, all `print()` output is redirected to stderr to keep stdout protocol-clean. `printVSink` is also set to stderr in the headless entry point.
- **isSafeForNonInteractive**: Commands that require confirmation (send, backup, seed) are gated in non-interactive mode unless `--yes` is passed.
