import 'dart:io';

import 'package:cake_headless/ports/user_interaction_port.dart';

/// CLI-based user interaction via stdin/stdout.
class StdinUserInteraction implements UserInteractionPort {
  final bool autoConfirm;

  StdinUserInteraction({this.autoConfirm = false});

  @override
  Future<bool> confirm(String message) async {
    if (autoConfirm) return true;
    stderr.write('$message [y/N] ');
    final input = stdin.readLineSync()?.trim().toLowerCase();
    return input == 'y' || input == 'yes';
  }

  @override
  Future<String?> promptText(String message, {bool obscure = false}) async {
    stderr.write('$message: ');
    if (obscure && stdin.hasTerminal) {
      stdin.echoMode = false;
    }
    final input = stdin.readLineSync();
    if (obscure && stdin.hasTerminal) {
      stdin.echoMode = true;
      stderr.writeln();
    }
    return input;
  }

  @override
  Future<int?> pickOption(String message, List<String> options) async {
    stderr.writeln(message);
    for (int i = 0; i < options.length; i++) {
      stderr.writeln('  ${i + 1}. ${options[i]}');
    }
    stderr.write('Choice [1-${options.length}]: ');
    final input = stdin.readLineSync()?.trim();
    if (input == null) return null;
    final idx = int.tryParse(input);
    if (idx == null || idx < 1 || idx > options.length) return null;
    return idx - 1;
  }
}
