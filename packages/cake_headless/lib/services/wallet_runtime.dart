import 'package:cake_headless/events/wallet_event.dart';
import 'package:cake_headless/runtime_context.dart';
import 'package:cw_core/wallet_info.dart';

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

  WalletRuntime(this.ctx);

  /// Wire callbacks on [ctx] that only need `cw_core` types.
  /// GetIt-dependent callbacks (loadWallet, sendTransaction, etc.)
  /// must be set by the entry point directly on [ctx].
  Future<void> wireAll() async {
    // Wire listWalletInfos — WalletInfo.getAll() reads from SQLite
    ctx.listWalletInfos = () => WalletInfo.getAll();
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
      }
    } catch (e) {
      ctx.logger.warn('Failed to auto-load wallet: $e');
    }
  }
}
