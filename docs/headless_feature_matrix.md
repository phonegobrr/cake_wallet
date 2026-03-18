# Headless Feature Parity Matrix

Track implementation status across all surfaces.

**Legend:** Y = implemented, S = scaffolded (command registered, stub response), P = placeholder UI only, - = not applicable, U = returns UNSUPPORTED_ON_PLATFORM

| Feature | Flutter Desktop | TUI | CLI | MCP | API |
|---|---|---|---|---|---|
| Wallet create | Y | | S | S | S |
| Wallet restore (seed) | Y | | S | S | S |
| Wallet restore (keys) | Y | | S | S | S |
| Wallet list | Y | Y | S | S | S |
| Wallet open/switch | Y | Y | S | S | S |
| Wallet close | Y | | S | S | S |
| Wallet delete | Y | Y | S | S | S |
| Wallet rename | Y | | S | S | S |
| Wallet seed | Y | | S | S | S |
| Wallet keys | Y | | S | S | S |
| Wallet rescan | Y | | S | S | S |
| Wallet sync start/stop | Y | | S | S | S |
| Balance display | Y | Y | S | S | S |
| Receive address | Y | Y | S | S | S |
| Receive list addresses | Y | | S | S | S |
| Receive new subaddress | Y | | S | S | S |
| Receive rotate | Y | | S | S | S |
| Receive URI | Y | | S | S | S |
| Receive label/hide/unhide | Y | | S | S | S |
| Send transaction | Y | Y | S | S | S |
| Send preview | Y | Y | S | S | S |
| Send max | Y | | S | S | S |
| Send all (sweep) | Y | | S | S | S |
| Send commit | Y | Y | S | S | S |
| Transaction history | Y | Y | S | S | S |
| Transaction details | Y | Y | S | S | S |
| Exchange/swap quote | Y | Y | S | S | S |
| Exchange/swap create | Y | | S | S | S |
| Exchange/swap status | Y | | S | S | S |
| Exchange providers | Y | | S | S | S |
| Exchange cancel | Y | | S | S | S |
| Node list | Y | Y | S | S | S |
| Node add | Y | | S | S | S |
| Node select | Y | Y | S | S | S |
| Node delete | Y | Y | S | S | S |
| Node edit | Y | | S | S | S |
| Node test | Y | | S | S | S |
| Node reset | Y | | S | S | S |
| Contact list | Y | Y | S | S | S |
| Contact add | Y | | S | S | S |
| Contact delete | Y | Y | S | S | S |
| Contact edit | Y | | S | S | S |
| Settings list | Y | Y | S | S | S |
| Settings get | Y | | S | S | S |
| Settings set | Y | | S | S | S |
| Backup export | Y | Y | S | S | S |
| Backup import | Y | Y | S | S | S |
| Backup verify | Y | Y | S | S | S |
| Sync status | Y | Y | S | S | S |
| Tor status | Y | | S | S | S |
| Tor enable/disable | Y | | S | S | S |
| Coin control (list/freeze/unfreeze) | Y | Y | S | S | S |
| Token management (list/add/remove) | Y | Y | S | S | S |
| Fiat conversion | Y | | S | S | S |
| Command palette | - | Y | - | - | - |
| Event streaming | - | Y | Y (`watch`) | Y | Y (SSE) |
| `--watch` flag | - | - | Y | - | - |
| Manifest output | - | - | Y (`manifest`) | - | Y |
| Sign/verify message | Y | | U | U | U |
| Buy/sell (fiat on-ramp) | Y | | U | U | U |
| Buy create | Y | | U | U | U |
| Sell providers/quote/create | Y | | U | U | U |
| Cake Pay (auth/cards/purchase/account) | Y | | U | U | U |
| Hardware wallets (list/connect/sign) | Y | | U | U | U |
| WalletConnect | Y | | U | U | U |
| Payjoin | Y | | U | U | U |

**S** = Command registered in command bus with real or stub response. CLI subcommand wired. MCP tool auto-exposed via command bus introspection. API endpoint available via `POST /api/v1/command/<name>`.

**U** = Command returns `UNSUPPORTED_ON_PLATFORM` error with a structured response.

**Note:** This matrix should be validated against `cake manifest` output. Rows marked S/Y should match commands with `status: implemented` or `status: stub` in the manifest.
