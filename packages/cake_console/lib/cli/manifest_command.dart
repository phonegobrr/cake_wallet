import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_console/cli/json_output.dart' show serializeData;

/// Output the command manifest as JSON.
class ManifestCommand extends Command<void> {
  @override
  String get name => 'manifest';
  @override
  String get description => 'Output command manifest as JSON';

  final CommandBus _bus;

  ManifestCommand(this._bus);

  @override
  Future<void> run() async {
    final manifest = {
      'version': '0.1.0',
      'generated': DateTime.now().toIso8601String(),
      'commands': _bus.commands
          .map((cmd) => {
                'name': cmd.name,
                'description': cmd.description,
                'safe_for_non_interactive': cmd.isSafeForNonInteractive,
                'status': cmd.status.name,
                'destructive': cmd.isDestructive,
                'args': cmd.args.map((k, v) => MapEntry(k, {
                      'type': v.type.toString(),
                      'required': v.required,
                      'description': v.description,
                      if (v.choices != null) 'choices': v.choices,
                      if (v.defaultValue != null) 'default': v.defaultValue,
                    })),
              })
          .toList()
        ..sort((a, b) =>
            (a['name'] as String).compareTo(b['name'] as String)),
    };

    stdout.writeln(const JsonEncoder.withIndent('  ').convert(manifest));
  }
}
