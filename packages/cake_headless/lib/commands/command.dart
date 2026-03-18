import 'package:cake_headless/commands/command_result.dart';
import 'package:cake_headless/runtime_context.dart';

/// Status of a command's implementation.
enum CommandStatus {
  implemented,
  stub,
  unsupported,
}

class CommandArg {
  final String name;
  final String description;
  final bool required;
  final Object? defaultValue;
  final Type type;
  final List<String>? choices;
  final bool secret;

  const CommandArg({
    required this.name,
    required this.description,
    this.required = false,
    this.defaultValue,
    this.type = String,
    this.choices,
    this.secret = false,
  });
}

abstract class WalletCommand<T> {
  String get name;
  String get description;
  Map<String, CommandArg> get args;
  bool get isSafeForNonInteractive => true;
  bool get isDestructive => false;
  CommandStatus get status => CommandStatus.implemented;

  Future<CommandResult<T>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  );
}
