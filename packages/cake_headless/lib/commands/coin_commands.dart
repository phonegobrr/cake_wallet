import 'package:cake_headless/commands/command.dart';
import 'package:cake_headless/commands/command_result.dart';
import 'package:cake_headless/runtime_context.dart';

class ListCoinsCommand extends WalletCommand<List<Map<String, dynamic>>> {
  @override
  String get name => 'coins.list';
  @override
  String get description => 'List unspent coins/UTXOs';
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
        message: 'Coin control requires UTXO-based wallet type and unspent coins info source');
  }
}

class FreezeCoinCommand extends WalletCommand<Map<String, String>> {
  @override
  String get name => 'coins.freeze';
  @override
  String get description => 'Freeze a coin/UTXO to exclude from spending';
  @override
  Map<String, CommandArg> get args => {
        'id': CommandArg(
            name: 'id', description: 'Coin/UTXO identifier', required: true),
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
        message: 'Coin control requires UTXO-based wallet type and unspent coins info source');
  }
}

class UnfreezeCoinCommand extends WalletCommand<Map<String, String>> {
  @override
  String get name => 'coins.unfreeze';
  @override
  String get description => 'Unfreeze a previously frozen coin/UTXO';
  @override
  Map<String, CommandArg> get args => {
        'id': CommandArg(
            name: 'id', description: 'Coin/UTXO identifier', required: true),
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
        message: 'Coin control requires UTXO-based wallet type and unspent coins info source');
  }
}
