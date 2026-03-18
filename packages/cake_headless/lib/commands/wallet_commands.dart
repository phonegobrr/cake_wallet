import 'package:cake_headless/commands/command.dart';
import 'package:cake_headless/commands/command_result.dart';
import 'package:cake_headless/dto/wallet_summary.dart';
import 'package:cake_headless/dto/balance_snapshot.dart';
import 'package:cake_headless/events/wallet_event.dart';
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
                  activeWallet.walletInfo.name == w.name &&
                  activeWallet.type == w.type,
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
    // Try to get formatted amounts using the wallet's currency formatter
    String? formatAmount(dynamic raw) {
      try {
        return wallet.currency.formatAmount(raw.toString());
      } catch (_) {
        return null;
      }
    }

    return CommandResult.ok(BalanceSnapshot(
      available: primaryBalance.available.toString(),
      pending: primaryBalance.additional.toString(),
      frozen: frozen.toString(),
      currencyTitle: wallet.currency.title,
      availableFormatted: formatAmount(primaryBalance.available),
      pendingFormatted: formatAmount(primaryBalance.additional),
      frozenFormatted: formatAmount(frozen),
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
      // Connect to node and start sync after loading
      if (ctx.connectAndSync != null) {
        try {
          await ctx.connectAndSync!();
        } catch (e) {
          ctx.logger.warn('Post-open node connection failed: $e');
        }
      }
      ctx.eventBus.emit(WalletEvent(WalletEventType.walletOpened,
          data: {'name': walletName, 'type': typeRaw}));
      // Notify runtime to wire post-load hooks (e.g. MobX reactions)
      ctx.onWalletLoaded?.call();
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
      ctx.eventBus.emit(WalletEvent(WalletEventType.walletClosed,
          data: {'name': name}));
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
            defaultValue: 0),
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

class CreateWalletCommand extends WalletCommand<WalletSummary> {
  @override
  String get name => 'wallet.create';
  @override
  String get description => 'Create a new wallet';
  @override
  Map<String, CommandArg> get args => {
        'name': CommandArg(
            name: 'name', description: 'Wallet name', required: true),
        'type': CommandArg(
            name: 'type',
            description: 'Wallet type index',
            type: int,
            required: true),
        'language': CommandArg(
            name: 'language',
            description: 'Seed language',
            defaultValue: 'English'),
      };

  @override
  Future<CommandResult<WalletSummary>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    if (ctx.createWallet == null) {
      return CommandResult.error('SERVICE_UNAVAILABLE',
          message: 'Wallet creation service not configured');
    }
    final walletName = params['name']?.toString() ?? '';
    final typeRaw = (params['type'] is int)
        ? params['type'] as int
        : int.tryParse(params['type']?.toString() ?? '') ?? -1;
    if (walletName.isEmpty || typeRaw < 0) {
      return CommandResult.error('INVALID_ARGS',
          message: 'Valid wallet name and type are required');
    }
    final language = params['language']?.toString() ?? 'English';

    try {
      final info =
          await ctx.createWallet!(walletName, typeRaw, language);
      return CommandResult.ok(
        WalletSummary(
          name: info.name,
          typeRaw: info.type.index,
          typeName: info.type.toString().split('.').last,
          isActive: false,
        ),
        message: 'Wallet "$walletName" created',
      );
    } catch (e) {
      return CommandResult.error('WALLET_CREATE_FAILED',
          message: e.toString());
    }
  }
}

class RestoreWalletSeedCommand extends WalletCommand<WalletSummary> {
  @override
  String get name => 'wallet.restore.seed';
  @override
  String get description => 'Restore wallet from seed phrase';
  @override
  Map<String, CommandArg> get args => {
        'name': CommandArg(
            name: 'name', description: 'Wallet name', required: true),
        'type': CommandArg(
            name: 'type',
            description: 'Wallet type index',
            type: int,
            required: true),
        'seed': CommandArg(
            name: 'seed',
            description: 'Seed phrase (space-separated)',
            required: true),
        'language': CommandArg(
            name: 'language',
            description: 'Seed language',
            defaultValue: 'English'),
      };

  @override
  bool get isSafeForNonInteractive => false;

  @override
  Future<CommandResult<WalletSummary>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    if (ctx.createWallet == null) {
      return CommandResult.error('SERVICE_UNAVAILABLE',
          message: 'Wallet creation service not configured');
    }
    final walletName = params['name']?.toString() ?? '';
    final typeRaw = (params['type'] is int)
        ? params['type'] as int
        : int.tryParse(params['type']?.toString() ?? '') ?? -1;
    final seed = params['seed']?.toString() ?? '';
    if (walletName.isEmpty || typeRaw < 0 || seed.isEmpty) {
      return CommandResult.error('INVALID_ARGS',
          message: 'Valid wallet name, type, and seed are required');
    }
    final language = params['language']?.toString() ?? 'English';

    try {
      final info = await ctx.createWallet!(walletName, typeRaw, language,
          seed: seed);
      return CommandResult.ok(
        WalletSummary(
          name: info.name,
          typeRaw: info.type.index,
          typeName: info.type.toString().split('.').last,
          isActive: false,
        ),
        message: 'Wallet "$walletName" restored from seed',
      );
    } catch (e) {
      return CommandResult.error('WALLET_RESTORE_FAILED',
          message: e.toString());
    }
  }
}

class DeleteWalletCommand extends WalletCommand<Map<String, String>> {
  @override
  String get name => 'wallet.delete';
  @override
  String get description => 'Delete a wallet';
  @override
  bool get isDestructive => true;
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
  bool get isSafeForNonInteractive => false;

  @override
  Future<CommandResult<Map<String, String>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    if (ctx.deleteWallet == null) {
      return CommandResult.error('SERVICE_UNAVAILABLE',
          message: 'Wallet deletion not configured');
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
      // Clear active wallet if we're deleting it
      if (ctx.hasWallet && ctx.wallet!.walletInfo.name == walletName) {
        ctx.wallet = null;
      }
      await ctx.deleteWallet!(walletName, typeRaw);
      return CommandResult.ok(
        {'deleted': walletName},
        message: 'Wallet "$walletName" deleted',
      );
    } catch (e) {
      return CommandResult.error('WALLET_DELETE_FAILED',
          message: e.toString());
    }
  }
}

class RenameWalletCommand extends WalletCommand<Map<String, String>> {
  @override
  String get name => 'wallet.rename';
  @override
  String get description => 'Rename a wallet';
  @override
  Map<String, CommandArg> get args => {
        'name': CommandArg(
            name: 'name', description: 'Current wallet name', required: true),
        'new-name': CommandArg(
            name: 'new-name', description: 'New wallet name', required: true),
        'type': CommandArg(
            name: 'type',
            description: 'Wallet type index',
            type: int,
            required: true),
      };

  @override
  Future<CommandResult<Map<String, String>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    if (ctx.renameWallet == null) {
      return CommandResult.error('SERVICE_UNAVAILABLE',
          message: 'Wallet rename not configured');
    }
    final oldName = params['name']?.toString() ?? '';
    final newName = params['new-name']?.toString() ?? '';
    final typeRaw = (params['type'] is int)
        ? params['type'] as int
        : int.tryParse(params['type']?.toString() ?? '') ?? -1;
    if (oldName.isEmpty || newName.isEmpty || typeRaw < 0) {
      return CommandResult.error('INVALID_ARGS',
          message: 'Valid old name, new name, and type are required');
    }

    try {
      await ctx.renameWallet!(oldName, newName, typeRaw);
      return CommandResult.ok(
        {'old': oldName, 'new': newName},
        message: 'Wallet renamed from "$oldName" to "$newName"',
      );
    } catch (e) {
      return CommandResult.error('WALLET_RENAME_FAILED',
          message: e.toString());
    }
  }
}

class RestoreWalletKeysCommand extends WalletCommand<Map<String, String>> {
  @override
  String get name => 'wallet.restore.keys';
  @override
  String get description => 'Restore wallet from private keys';
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
  bool get isSafeForNonInteractive => false;

  @override
  Future<CommandResult<Map<String, String>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    // Key-based restore requires wallet-type-specific key formats
    // (e.g. Monero: spendKey+viewKey+address, Bitcoin: WIF, etc.)
    // This must be wired through a wallet-type-specific callback
    return CommandResult.error('SERVICE_UNAVAILABLE',
        message: 'Key-based restore requires wallet-type-specific key format handling. '
            'Use wallet.restore.seed for seed-based restore.');
  }
}

class SyncStartCommand extends WalletCommand<Map<String, String>> {
  @override
  String get name => 'wallet.sync.start';
  @override
  String get description => 'Start wallet synchronization';
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
    try {
      await ctx.wallet!.startSync();
      return CommandResult.ok(
        {'status': 'syncing'},
        message: 'Synchronization started',
      );
    } catch (e) {
      return CommandResult.error('SYNC_START_FAILED', message: e.toString());
    }
  }
}

class SyncStopCommand extends WalletCommand<Map<String, String>> {
  @override
  String get name => 'wallet.sync.stop';
  @override
  String get description => 'Stop wallet synchronization';
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
    try {
      await ctx.wallet!.stopSync();
      return CommandResult.ok(
        {'status': 'stopped'},
        message: 'Synchronization stopped',
      );
    } catch (e) {
      return CommandResult.error('SYNC_STOP_FAILED', message: e.toString());
    }
  }
}

class SignMessageCommand extends WalletCommand<Map<String, String>> {
  @override
  String get name => 'wallet.sign';
  @override
  String get description => 'Sign a message with wallet key';
  @override
  Map<String, CommandArg> get args => {
        'message': CommandArg(
            name: 'message', description: 'Message to sign', required: true),
        'address': CommandArg(
            name: 'address', description: 'Address to sign with (optional)'),
      };

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
    final message = params['message']?.toString() ?? '';
    final address = params['address']?.toString();

    try {
      final signature = await ctx.wallet!.signMessage(message, address: address);
      return CommandResult.ok(
        {'signature': signature, 'message': message},
        message: 'Message signed',
      );
    } catch (e) {
      return CommandResult.error('SIGN_FAILED', message: e.toString());
    }
  }
}

class VerifyMessageCommand extends WalletCommand<Map<String, dynamic>> {
  @override
  String get name => 'wallet.verify';
  @override
  String get description => 'Verify a signed message';
  @override
  Map<String, CommandArg> get args => {
        'message': CommandArg(
            name: 'message', description: 'Original message', required: true),
        'signature': CommandArg(
            name: 'signature', description: 'Signature to verify', required: true),
        'address': CommandArg(
            name: 'address', description: 'Address that signed (optional)'),
      };

  @override
  Future<CommandResult<Map<String, dynamic>>> execute(
    CakeRuntimeContext ctx,
    Map<String, dynamic> params,
  ) async {
    if (!ctx.hasWallet) {
      return CommandResult.error('NO_WALLET', message: ctx.strings.noWalletOpen);
    }
    final message = params['message']?.toString() ?? '';
    final signature = params['signature']?.toString() ?? '';
    final address = params['address']?.toString();

    try {
      final valid = await ctx.wallet!.verifyMessage(message, signature,
          address: address);
      return CommandResult.ok(
        {'valid': valid, 'message': message},
        message: valid ? 'Signature valid' : 'Signature invalid',
      );
    } catch (e) {
      return CommandResult.error('VERIFY_FAILED', message: e.toString());
    }
  }
}
