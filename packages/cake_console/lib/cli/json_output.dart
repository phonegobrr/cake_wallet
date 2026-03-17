import 'dart:convert';
import 'dart:io';

import 'package:cake_headless/commands/command_result.dart';

/// Renders a CommandResult as JSON to stdout.
void outputJson(CommandResult result) {
  final json = result.toJson((data) {
    if (data is Map) return data as Map<String, dynamic>;
    if (data is List) {
      return {'items': data.map((e) {
        if (e is Map) return e;
        final toJsonMethod = (e as dynamic).toJson;
        if (toJsonMethod != null) return toJsonMethod();
        return {'value': e.toString()};
      }).toList()};
    }
    final toJsonMethod = (data as dynamic).toJson;
    if (toJsonMethod != null) return toJsonMethod() as Map<String, dynamic>;
    return {'value': data.toString()};
  });
  stdout.writeln(jsonEncode(json));
}

/// Renders a CommandResult as human-readable text to stdout.
void outputText(CommandResult result) {
  if (!result.success) {
    stderr.writeln('Error: ${result.message ?? result.errorCode ?? "Unknown error"}');
    return;
  }
  if (result.message != null) {
    stdout.writeln(result.message);
  }
  if (result.data != null) {
    final data = result.data;
    if (data is List) {
      for (final item in data) {
        stdout.writeln('  $item');
      }
    } else {
      stdout.writeln(result.data);
    }
  }
}
