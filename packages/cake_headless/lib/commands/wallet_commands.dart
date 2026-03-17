import 'package:cake_headless/commands/command.dart';
import 'package:cake_headless/commands/command_result.dart';
import 'package:cake_headless/dto/wallet_summary.dart';
import 'package:cake_headless/dto/balance_snapshot.dart';
import 'package:cake_headless/runtime_context.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';

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
    if (ctx.listWalletInfos == null) {
      return CommandResult.ok(<WalletSummary>[],
          message: 'Wallet services not initialized');
    }
    final wallets = (await ctx.listWalletInfos!()).cast<WalletInfo>();
    final activeWallet = ctx.wallet as WalletBase?;
    return CommandResult.ok(wallets
        .map((w) => WalletSummary(
              name: w.name,
              typeRaw: w.type.index,
              typeName: w.type.toString().split('.').last,
              isActive: activeWallet != null &&
                  activeWallet.walletInfo.name == w.name,
            ))
        .toList());
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
    final wallet = ctx.wallet as WalletBase?;
    if (wallet == null) {
      return CommandResult.error('NO_WALLET', message: ctx.strings.noWalletOpen);
    }
    final balanceMap = wallet.balance;
    if (balanceMap.isEmpty) {
      return CommandResult.error('NO_BALANCE', message: 'No balance available');
    }
    final primaryBalance = balanceMap.values.first;
    return CommandResult.ok(BalanceSnapshot(
      available: primaryBalance.available.toString(),
      pending: primaryBalance.additional.toString(),
      frozen: (primaryBalance.frozen ?? BigInt.zero).toString(),
      currencyTitle: wallet.currency.title,
    ));
  }
}
