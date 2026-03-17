import 'package:cake_headless/commands/command.dart';
import 'package:cake_headless/commands/command_result.dart';
import 'package:cake_headless/runtime_context.dart';

class ListTokensCommand extends WalletCommand<List<Map<String, dynamic>>> {
  @override
  String get name => 'tokens.list';
  @override
  String get description => 'List tokens for the current wallet';
  @override
  Map<String, CommandArg> get args => {};

  @override
  Future<CommandResult<List<Map<String, dynamic>>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    if (!ctx.hasWallet) {
      return CommandResult.error('NO_WALLET', message: ctx.strings.noWalletOpen);
    }
    return CommandResult.error('SERVICE_UNAVAILABLE',
        message: 'Token management requires EVM/SPL/TRC wallet type');
  }
}

class AddTokenCommand extends WalletCommand<Map<String, String>> {
  @override
  String get name => 'tokens.add';
  @override
  String get description => 'Add a token to the wallet';
  @override
  Map<String, CommandArg> get args => {
        'address': CommandArg(
            name: 'address',
            description: 'Token contract address',
            required: true),
      };

  @override
  Future<CommandResult<Map<String, String>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    if (!ctx.hasWallet) {
      return CommandResult.error('NO_WALLET', message: ctx.strings.noWalletOpen);
    }
    return CommandResult.error('SERVICE_UNAVAILABLE',
        message: 'Token management requires EVM/SPL/TRC wallet type');
  }
}

class RemoveTokenCommand extends WalletCommand<Map<String, String>> {
  @override
  String get name => 'tokens.remove';
  @override
  String get description => 'Remove a token from the wallet';
  @override
  Map<String, CommandArg> get args => {
        'address': CommandArg(
            name: 'address',
            description: 'Token contract address',
            required: true),
      };

  @override
  Future<CommandResult<Map<String, String>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    if (!ctx.hasWallet) {
      return CommandResult.error('NO_WALLET', message: ctx.strings.noWalletOpen);
    }
    return CommandResult.error('SERVICE_UNAVAILABLE',
        message: 'Token management requires EVM/SPL/TRC wallet type');
  }
}
