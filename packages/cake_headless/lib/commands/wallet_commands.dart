import 'package:cake_headless/commands/command.dart';
import 'package:cake_headless/commands/command_result.dart';
import 'package:cake_headless/dto/wallet_summary.dart';
import 'package:cake_headless/dto/balance_snapshot.dart';
import 'package:cake_headless/runtime_context.dart';

class ListWalletsCommand extends WalletCommand<List<WalletSummary>> {
  @override
  String get name => 'wallet.list';
  @override
  String get description => 'List all wallets';
  @override
  Map<String, CommandArg> get args => {};

  @override
  Future<CommandResult<List<WalletSummary>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    // Placeholder: will be wired to WalletLoadingService
    ctx.logger.info('Listing wallets...');
    return CommandResult.ok(<WalletSummary>[],
        message: 'No wallets configured yet');
  }
}

class GetBalanceCommand extends WalletCommand<BalanceSnapshot> {
  @override
  String get name => 'balance.get';
  @override
  String get description => 'Get current wallet balance';
  @override
  Map<String, CommandArg> get args => {};

  @override
  Future<CommandResult<BalanceSnapshot>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    ctx.logger.info('Getting balance...');
    return CommandResult.error('NO_WALLET', message: ctx.strings.noWalletOpen);
  }
}
