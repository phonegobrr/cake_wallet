# Headless Feature Parity Matrix

Track implementation status across all surfaces.

**Legend:** Y = implemented, S = scaffolded (command registered, stub response), - = not applicable

| Feature | Flutter Desktop | TUI | CLI (headless) | MCP Tool |
|---|---|---|---|---|
| Wallet create | Y | | | |
| Wallet restore (seed) | Y | | | |
| Wallet restore (keys) | Y | | | |
| Wallet list/switch | Y | S | S | S |
| Balance display | Y | S | S | S |
| Receive address | Y | S | S | S |
| Send transaction | Y | S | S | S |
| Transaction history | Y | S | S | S |
| Exchange/swap | Y | S | | |
| Node management | Y | | S | S |
| Contact management | Y | S | | |
| Settings | Y | S | S | S |
| Backup/restore | Y | | | |
| Sync status | Y | S | S | S |
| Coin control | Y | | | |
| Wallet keys export | Y | | | |
| Seed display/verify | Y | | | |
| Fiat conversion | Y | | | |
| Address book | Y | | | |
| Sign/verify message | Y | | | |
| Payjoin | Y | | | |
| Lightning | Y | | | |
| Silent payments | Y | | | |
| MWEB | Y | | | |
| WalletConnect | Y | | | - |
| Cake Pay | Y | | | |
| Buy/sell | Y | | | |
| Hardware wallets | Y | | | - |
| 2FA | Y | | | |
| Tor | Y | | | |

Fill columns as features are implemented. Use `router.dart` routes as the canonical desktop feature list.

## Architecture Notes

- **Command Bus**: All headless commands are registered in `packages/cake_headless/lib/commands/`. Each command maps 1:1 to a CLI subcommand, MCP tool, and TUI screen action.
- **MCP Server**: `cake mcp` starts a JSON-RPC 2.0 server over stdio. All registered commands are automatically exposed as MCP tools.
- **TUI**: `cake tui` (or just `cake` with no args) launches the interactive terminal UI with dart_lipgloss styling.
- **CLI**: `cake <command> [--json]` runs headless commands with optional JSON output.
