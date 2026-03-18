# Agent Instructions

## Headless / TUI / MCP Development

### Architecture
- `cake_console` must NOT import `package:flutter/*` — it compiles with `dart compile exe`
- Business logic goes in `cake_headless` or the bridge package, not in TUI/CLI/MCP layers
- The command registry (`CommandBus`) is the single source of truth for all transport surfaces
- Host mode (`cake host`) owns wallet state and locks; all clients dispatch through shared CommandBus

### Development Setup
- TUI uses local `dart_lipgloss` override during development
- Local checkout: `~/Desktop/working/dark_lipgloss` (note: folder `dark_lipgloss`, package `dart_lipgloss`)
- Use `packages/cake_console/pubspec_overrides.yaml` (gitignored) — see `pubspec_overrides.example.yaml`

### Key Conventions
- Keep stdout clean in MCP mode — all debug/log output to stderr
- Use official MCP lifecycle + transport semantics (stdio, Streamable HTTP)
- Generated capability manifest (`cake manifest`) is canonical
- Every new feature must land in shared command/service layer first
- When moving models from cake_wallet to cw_core, create re-export shims at original locations
- Preserve Hive `typeId` values when moving models — changing them corrupts local databases
- Use `registerCoreHiveAdapters()` from `cw_core/lib/register_adapters.dart` for adapter registration

### Error Codes
- `UNKNOWN_COMMAND` — command not found
- `MISSING_ARG` — required argument missing
- `INVALID_ARGS` — invalid argument values
- `INVALID_ARG_TYPE` — wrong type for argument
- `SERVICE_UNAVAILABLE` — service not wired/configured
- `UNSUPPORTED_ON_PLATFORM` — intentionally unsupported in headless
- `INTERACTION_REQUIRED` — needs interactive confirmation
- `CONFIRMATION_REQUIRED` — non-interactive mode cannot confirm
