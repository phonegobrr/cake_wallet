import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cake_headless/events/event_bus.dart';

/// Stream wallet events as NDJSON to stdout.
/// Enables `cake watch | jq '.data.balance'` for monitoring.
class WatchCommand extends Command<void> {
  @override
  String get name => 'watch';
  @override
  String get description => 'Stream wallet events as NDJSON';

  final WalletEventBus _eventBus;

  WatchCommand(this._eventBus);

  @override
  Future<void> run() async {
    await for (final event in _eventBus.events) {
      stdout.writeln(jsonEncode({
        'type': event.type.name,
        'data': event.data,
        'timestamp': event.timestamp.toIso8601String(),
      }));
    }
  }
}
