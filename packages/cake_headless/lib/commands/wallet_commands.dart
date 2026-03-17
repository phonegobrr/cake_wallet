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
    final List<WalletInfo> wallets;
    try {
      wallets = (await ctx.listWalletInfos!()).whereType<WalletInfo>().toList();
    } on TypeError catch (e) {
      return CommandResult.error('TYPE_ERROR',
          message: 'listWalletInfos returned unexpected type: $e');
    }
    final activeWallet = ctx.wallet is WalletBase ? ctx.wallet as WalletBase : null;
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
    if (ctx.wallet == null || ctx.wallet is! WalletBase) {
      return CommandResult.error('NO_WALLET', message: ctx.strings.noWalletOpen);
    }
    final wallet = ctx.wallet as WalletBase;
    final balanceMap = wallet.balance;
    if (balanceMap.isEmpty) {
      return CommandResult.error('NO_BALANCE', message: 'No balance available');
    }
    final primaryBalance = balanceMap.values.first;
    // Not all wallet Balance implementations have a `frozen` getter
    final frozen = (() {
      try {
        return (primaryBalance as dynamic).frozen ?? BigInt.zero;
      } catch (_) {
        return BigInt.zero;
      }
    })();
    return CommandResult.ok(BalanceSnapshot(
      available: primaryBalance.available.toString(),
      pending: primaryBalance.additional.toString(),
      frozen: frozen.toString(),
      currencyTitle: wallet.currency.title,
    ));
  }
}
