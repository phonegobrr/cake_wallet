import 'package:cake_headless/commands/command.dart';
import 'package:cake_headless/commands/command_result.dart';
import 'package:cake_headless/runtime_context.dart';

class TorStatusCommand extends WalletCommand<Map<String, dynamic>> {
  @override
  String get name => 'tor.status';
  @override
  String get description => 'Get Tor connection status';
  @override
  Map<String, CommandArg> get args => {};

  @override
  Future<CommandResult<Map<String, dynamic>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    // Tor status requires CakeTor singleton which is initialized at the entry point
    return CommandResult.error('SERVICE_UNAVAILABLE',
        message: 'Tor status requires runtime initialization');
  }
}

class TorEnableCommand extends WalletCommand<Map<String, String>> {
  @override
  String get name => 'tor.enable';
  @override
  String get description => 'Enable Tor connection';
  @override
  Map<String, CommandArg> get args => {};

  @override
  Future<CommandResult<Map<String, String>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    return CommandResult.error('SERVICE_UNAVAILABLE',
        message: 'Tor control requires runtime initialization');
  }
}

class TorDisableCommand extends WalletCommand<Map<String, String>> {
  @override
  String get name => 'tor.disable';
  @override
  String get description => 'Disable Tor connection';
  @override
  Map<String, CommandArg> get args => {};

  @override
  Future<CommandResult<Map<String, String>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    return CommandResult.error('SERVICE_UNAVAILABLE',
        message: 'Tor control requires runtime initialization');
  }
}
