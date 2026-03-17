# Headless Feature Parity Matrix

Track implementation status across all surfaces.

**Legend:** Y = implemented, S = scaffolded (command registered, stub response), P = placeholder UI only, - = not applicable

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
| Exchange/swap | Y | P | | |
| Node management | Y | | S | S |
| Contact management | Y | P | | |
| Settings | Y | P | S | S |
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

**S** = Command registered in command bus + stub response (returns placeholder data or NO_WALLET error). CLI subcommand wired. MCP tool auto-exposed via command bus introspection.

**P** = TUI screen exists with placeholder "coming soon" message. No command bus dispatch.

Fill columns as features are implemented. Use `router.dart` routes as the canonical desktop feature list.

## Architecture Notes

- **Command Bus**: All headless commands are registered in `packages/cake_headless/lib/bootstrap.dart`. Each registered command is automatically available as a CLI subcommand and MCP tool.
- **MCP Server**: `cake mcp` starts a JSON-RPC 2.0 server over stdio. Introspects the command bus to expose all registered commands as MCP tools.
- **TUI**: `cake tui` (or just `cake` with no args) launches the interactive terminal UI with dart_lipgloss styling. Screens with "S" status dispatch through the command bus; "P" screens show placeholder UI only.
- **CLI**: `cake <command> [--json]` runs headless commands with optional JSON output.
