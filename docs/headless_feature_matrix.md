# Headless Feature Parity Matrix

Track implementation status across all surfaces.

**Legend:** Y = implemented, S = scaffolded (command registered, stub response), P = placeholder UI only, - = not applicable, U = returns UNSUPPORTED_ON_PLATFORM

| Feature | Flutter Desktop | TUI | CLI (headless) | MCP Tool |
|---|---|---|---|---|
| Wallet create | Y | | | |
| Wallet restore (seed) | Y | | | |
| Wallet restore (keys) | Y | | | |
| Wallet list | Y | S | S | S |
| Wallet open/switch | Y | S | S | S |
| Wallet close | Y | | S | S |
| Wallet seed | Y | | S | S |
| Wallet keys | Y | | S | S |
| Wallet rescan | Y | | S | S |
| Balance display | Y | S | S | S |
| Receive address | Y | S | S | S |
| Send transaction | Y | S | S | S |
| Transaction history | Y | S | S | S |
| Exchange/swap quote | Y | S | S | S |
| Exchange/swap status | Y | | S | S |
| Node list | Y | | S | S |
| Node add | Y | | S | S |
| Node select | Y | | S | S |
| Node delete | Y | | S | S |
| Node test | Y | | S | S |
| Contact list | Y | S | S | S |
| Contact add | Y | | S | S |
| Contact delete | Y | | S | S |
| Settings list | Y | S | S | S |
| Settings get | Y | | S | S |
| Settings set | Y | | S | S |
| Backup export | Y | | S | S |
| Backup import | Y | | S | S |
| Sync status | Y | S | S | S |
| Coin control | Y | | | |
| Fiat conversion | Y | | | |
| Address book | Y | | | |
| Sign/verify message | Y | | | |
| Payjoin | Y | | | U |
| Lightning | Y | | | U |
| Silent payments | Y | | | U |
| MWEB | Y | | | U |
| WalletConnect | Y | | | - |
| Cake Pay | Y | | | |
| Buy/sell | Y | | | |
| Hardware wallets | Y | | | - |
| 2FA | Y | | | |
| Tor | Y | | | |

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
- **No-stdout rule**: In MCP mode, all `print()` output is redirected to stderr to keep stdout protocol-clean.
- **isSafeForNonInteractive**: Commands that require confirmation (send, backup, seed) are gated in non-interactive mode unless `--yes` is passed.
