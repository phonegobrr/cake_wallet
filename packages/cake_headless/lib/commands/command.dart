import 'package:cake_headless/commands/command_result.dart';
import 'package:cake_headless/runtime_context.dart';

class CommandArg {
  final String name;
  final String description;
  final bool required;
  final String? defaultValue;
  final Type type;

  const CommandArg({
    required this.name,
    required this.description,
    this.required = false,
    this.defaultValue,
    this.type = String,
  });
}

abstract class WalletCommand<T> {
  String get name;
  String get description;
  Map<String, CommandArg> get args;
  bool get isSafeForNonInteractive => true;

  Future<CommandResult<T>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  );
}
