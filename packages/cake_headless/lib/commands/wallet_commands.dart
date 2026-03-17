import 'package:cake_headless/commands/command.dart';
import 'package:cake_headless/commands/command_result.dart';
import 'package:cake_headless/dto/wallet_summary.dart';
import 'package:cake_headless/dto/balance_snapshot.dart';
import 'package:cake_headless/runtime_context.dart';
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
      wallets = await ctx.listWalletInfos!();
    } catch (e) {
      return CommandResult.error('TYPE_ERROR',
          message: 'Failed to list wallets: $e');
    }
    final activeWallet = ctx.wallet;
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
    if (!ctx.hasWallet) {
      return CommandResult.error('NO_WALLET', message: ctx.strings.noWalletOpen);
    }
    final wallet = ctx.wallet!;
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

class OpenWalletCommand extends WalletCommand<WalletSummary> {
  @override
  String get name => 'wallet.open';
  @override
  String get description => 'Open/switch to a wallet by name';
  @override
  Map<String, CommandArg> get args => {
        'name': CommandArg(
            name: 'name', description: 'Wallet name', required: true),
        'type': CommandArg(
            name: 'type',
            description: 'Wallet type index',
            type: int,
            required: true),
      };

  @override
  Future<CommandResult<WalletSummary>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    if (ctx.loadWallet == null) {
      return CommandResult.error('SERVICE_UNAVAILABLE',
          message: 'Wallet loading service not configured');
    }
    final walletName = params['name']?.toString() ?? '';
    final typeRaw = (params['type'] is int)
        ? params['type'] as int
        : int.tryParse(params['type']?.toString() ?? '') ?? -1;

    if (walletName.isEmpty || typeRaw < 0) {
      return CommandResult.error('INVALID_ARGS',
          message: 'Valid wallet name and type are required');
    }

    try {
      await ctx.loadWallet!(walletName, typeRaw);
      return CommandResult.ok(
        WalletSummary(
          name: walletName,
          typeRaw: typeRaw,
          typeName: ctx.wallet?.type.toString().split('.').last ?? 'unknown',
          isActive: true,
        ),
        message: 'Wallet "$walletName" opened',
      );
    } catch (e) {
      return CommandResult.error('WALLET_OPEN_FAILED', message: e.toString());
    }
  }
}

class CloseWalletCommand extends WalletCommand<Map<String, String>> {
  @override
  String get name => 'wallet.close';
  @override
  String get description => 'Close the current wallet';
  @override
  Map<String, CommandArg> get args => {};

  @override
  Future<CommandResult<Map<String, String>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    if (!ctx.hasWallet) {
      return CommandResult.error('NO_WALLET', message: ctx.strings.noWalletOpen);
    }
    final name = ctx.wallet!.walletInfo.name;
    try {
      await ctx.wallet!.close(shouldCleanup: false);
      ctx.wallet = null;
      return CommandResult.ok(
        {'closed': name},
        message: 'Wallet "$name" closed',
      );
    } catch (e) {
      ctx.wallet = null;
      ctx.logger.warn('Wallet close had errors: $e');
      return CommandResult.ok(
        {'closed': name, 'warning': e.toString()},
        message: 'Wallet "$name" closed with warnings',
      );
    }
  }
}

class GetWalletSeedCommand extends WalletCommand<Map<String, String>> {
  @override
  String get name => 'wallet.seed';
  @override
  String get description => 'Show wallet seed phrase';
  @override
  Map<String, CommandArg> get args => {};

  @override
  bool get isSafeForNonInteractive => false;

  @override
  Future<CommandResult<Map<String, String>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    if (!ctx.hasWallet) {
      return CommandResult.error('NO_WALLET', message: ctx.strings.noWalletOpen);
    }
    final wallet = ctx.wallet!;
    final seed = wallet.seed;
    if (seed == null || seed.isEmpty) {
      return CommandResult.error('NO_SEED',
          message: 'This wallet does not have a seed phrase');
    }
    return CommandResult.ok({'seed': seed});
  }
}

class GetWalletKeysCommand extends WalletCommand<Map<String, String>> {
  @override
  String get name => 'wallet.keys';
  @override
  String get description => 'Show wallet keys';
  @override
  Map<String, CommandArg> get args => {};

  @override
  bool get isSafeForNonInteractive => false;

  @override
  Future<CommandResult<Map<String, String>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    if (!ctx.hasWallet) {
      return CommandResult.error('NO_WALLET', message: ctx.strings.noWalletOpen);
    }
    final wallet = ctx.wallet!;
    try {
      final rawKeys = (wallet as dynamic).keys;
      if (rawKeys == null) {
        return CommandResult.error('NO_KEYS',
            message: 'Key export not supported for this wallet type');
      }
      // Convert keys object to string map — works with Map and toString fallback
      final Map<String, String> keysMap;
      if (rawKeys is Map<String, String>) {
        keysMap = rawKeys;
      } else if (rawKeys is Map) {
        keysMap = rawKeys.map((k, v) => MapEntry(k.toString(), v.toString()));
      } else {
        keysMap = {'keys': rawKeys.toString()};
      }
      return CommandResult.ok(keysMap);
    } catch (_) {
      return CommandResult.error('NO_KEYS',
          message: 'Key export not supported for this wallet type');
    }
  }
}

class RescanWalletCommand extends WalletCommand<Map<String, String>> {
  @override
  String get name => 'wallet.rescan';
  @override
  String get description => 'Rescan wallet from a given height';
  @override
  Map<String, CommandArg> get args => {
        'height': CommandArg(
            name: 'height',
            description: 'Block height to rescan from',
            type: int,
            defaultValue: '0'),
      };

  @override
  Future<CommandResult<Map<String, String>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    if (!ctx.hasWallet) {
      return CommandResult.error('NO_WALLET', message: ctx.strings.noWalletOpen);
    }
    final height = (params['height'] is int)
        ? params['height'] as int
        : int.tryParse(params['height']?.toString() ?? '0') ?? 0;

    try {
      await ctx.wallet!.rescan(height: height);
      return CommandResult.ok(
        {'height': height.toString()},
        message: 'Rescan started from height $height',
      );
    } catch (e) {
      return CommandResult.error('RESCAN_FAILED', message: e.toString());
    }
  }
}
