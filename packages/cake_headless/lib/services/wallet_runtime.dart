import 'package:cake_headless/events/wallet_event.dart';
import 'package:cake_headless/runtime_context.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:mobx/mobx.dart';

/// Bridge between [CakeRuntimeContext] and the GetIt DI container.
///
/// Wires the callbacks on [ctx] that can be connected using only
/// `cw_core` types (no Flutter or GetIt dependency). The entry point
/// is responsible for wiring callbacks that require GetIt-registered
/// services (loadWallet, sendTransaction, etc.) directly on [ctx]
/// after calling [wireAll].
///
/// Usage in cake.dart:
/// ```dart
/// final runtime = WalletRuntime(ctx);
/// await runtime.wireAll();
/// // Then wire GetIt-dependent callbacks directly on ctx:
/// // ctx.loadWallet = ...
/// // ctx.sendTransaction = ...
/// await runtime.autoLoadCurrentWallet();
/// ```
class WalletRuntime {
  final CakeRuntimeContext ctx;
  final List<ReactionDisposer> _disposers = [];

  WalletRuntime(this.ctx);

  /// Wire callbacks on [ctx] that only need `cw_core` types.
  /// GetIt-dependent callbacks (loadWallet, sendTransaction, etc.)
  /// must be set by the entry point directly on [ctx].
  Future<void> wireAll() async {
    // Wire listWalletInfos — WalletInfo.getAll() reads from SQLite
    ctx.listWalletInfos = () => WalletInfo.getAll();
  }

  /// Set up MobX reactions on the current wallet to emit events
  /// to [WalletEventBus] when sync status or balance changes.
  /// Call this after a wallet has been loaded on [ctx.wallet].
  void wireWalletReactions() {
    // Dispose any existing reactions from a previous wallet
    disposeReactions();

    final wallet = ctx.wallet;
    if (wallet == null) return;

    // Emit sync status changes
    _disposers.add(reaction<SyncStatus>(
      (_) => wallet.syncStatus,
      (status) {
        ctx.eventBus.emit(WalletEvent(
          WalletEventType.syncStatusChanged,
          data: {
            'progress': status.progress(),
            'display': status.toString(),
            'wallet': wallet.walletInfo.name,
          },
        ));
      },
    ));

    // Emit balance changes
    _disposers.add(reaction<Map>(
      (_) => wallet.balance,
      (balanceMap) {
        final data = <String, dynamic>{
          'wallet': wallet.walletInfo.name,
        };
        for (final entry in balanceMap.entries) {
          data[entry.key.title] = entry.value.available.toString();
        }
        ctx.eventBus.emit(WalletEvent(
          WalletEventType.balanceChanged,
          data: data,
        ));
      },
    ));
  }

  /// Dispose all active MobX reactions.
  void disposeReactions() {
    for (final d in _disposers) {
      d();
    }
    _disposers.clear();
  }

  /// Try to auto-load the last used wallet using the loadWallet callback.
  /// Requires [ctx.loadWallet] and a settings store with wallet name/type.
  Future<void> autoLoadCurrentWallet() async {
    if (ctx.loadWallet == null) {
      ctx.logger.debug('loadWallet not wired — skipping auto-load');
      return;
    }

    try {
      final name = await ctx.settings.getString('current_wallet_name');
      final typeRaw = await ctx.settings.getInt('current_wallet_type');

      if (name != null && typeRaw != null) {
        ctx.logger.info('Auto-loading wallet "$name" (type: $typeRaw)');
        await ctx.loadWallet!(name, typeRaw);
        wireWalletReactions();
      }
    } catch (e) {
      ctx.logger.warn('Failed to auto-load wallet: $e');
    }
  }
}
