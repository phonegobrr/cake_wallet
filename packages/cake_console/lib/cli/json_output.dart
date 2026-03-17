import 'dart:convert';
import 'dart:io';

import 'package:cake_headless/commands/command_result.dart';

/// Serializes any DTO or value to a JSON-friendly structure.
dynamic serializeData(dynamic data) {
  if (data == null) return {};
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  if (data is List) {
    return {
      'items': data.map((e) => serializeData(e)).toList(),
    };
  }
  if (data is String || data is num || data is bool) {
    return {'value': data};
  }
  try {
    final result = (data as dynamic).toJson();
    if (result is Map<String, dynamic>) return result;
    return {'value': result.toString()};
  } catch (_) {
    return {'value': data.toString()};
  }
}

/// Renders a CommandResult as JSON to stdout.
void outputJson(CommandResult result) {
  final json = result.toJson((data) => serializeData(data));
  stdout.writeln(jsonEncode(json));
}

/// Formats a single data item as a human-readable string.
String _formatItem(dynamic item) {
  try {
    final json = (item as dynamic).toJson();
    if (json is Map) {
      return json.entries.map((e) => '${e.key}: ${e.value}').join('  ');
    }
    return json.toString();
  } catch (_) {
    return item.toString();
  }
}

/// Renders a CommandResult as human-readable text to stdout.
void outputText(CommandResult result) {
  if (!result.success) {
    stderr.writeln(
        'Error: ${result.message ?? result.errorCode ?? "Unknown error"}');
    return;
  }
  if (result.message != null) {
    stdout.writeln(result.message);
  }
  if (result.data != null) {
    final data = result.data;
    if (data is List) {
      if (data.isEmpty) {
        stdout.writeln('  (none)');
      } else {
        for (final item in data) {
          stdout.writeln('  ${_formatItem(item)}');
        }
      }
    } else if (data is Map) {
      for (final entry in data.entries) {
        stdout.writeln('  ${entry.key}: ${entry.value}');
      }
    } else {
      stdout.writeln('  ${_formatItem(data)}');
    }
  }
}
