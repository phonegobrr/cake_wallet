import 'package:cake_headless/dto/address_entry.dart';
import 'package:cake_headless/dto/node_info.dart';
import 'package:cake_headless/events/wallet_event.dart';
import 'package:cake_headless/runtime_context.dart';
import 'package:cw_core/wallet_info.dart';

/// Bridge between [CakeRuntimeContext] and the GetIt DI container.
///
/// This is the single integration layer that wires headless runtime callbacks
/// to the actual wallet services registered via GetIt. Entry points call
/// [wireAll] after [initializeHeadless] has completed.
///
/// Usage in cake.dart:
/// ```dart
/// await initializeHeadless(dataDir: appDir, secureStorage: adapter);
/// final runtime = WalletRuntime(ctx);
/// await runtime.wireAll();
/// await runtime.autoLoadCurrentWallet();
/// ```
class WalletRuntime {
  final CakeRuntimeContext ctx;

  WalletRuntime(this.ctx);

  /// Wire all callbacks on [ctx] to the GetIt-registered services.
  /// Call this after [initializeHeadless] has completed.
  Future<void> wireAll() async {
    // Wire listWalletInfos — WalletInfo.getAll() reads from SQLite
    ctx.listWalletInfos = () => WalletInfo.getAll();

    // Wire loadWallet — requires WalletLoadingService from GetIt
    ctx.loadWallet = _loadWallet;

    // Wire listContacts, listNodes, addContact, deleteContact, addNode,
    // selectNode, deleteNode — these will be connected to Hive boxes
    // and services once the full DI container is available.
    //
    // For now, these remain null and commands return SERVICE_UNAVAILABLE.
    // The entry point (cake.dart) sets these after initializeHeadless()
    // when GetIt has the required service registrations.
  }

  /// Load a wallet by name and wallet type index.
  /// This method is designed to be called from the headless runtime context.
  Future<void> _loadWallet(String name, int walletTypeRaw) async {
    // Dynamic import to avoid hard dependency on Flutter-coupled DI
    // The actual loading is done through GetIt when available
    try {
      final getIt = _tryGetIt();
      if (getIt == null) {
        throw StateError('GetIt not initialized — call initializeHeadless() first');
      }

      // Use WalletLoadingService from GetIt
      final loadingService = getIt.call<dynamic>(instanceName: 'WalletLoadingService');
      if (loadingService == null) {
        throw StateError('WalletLoadingService not registered');
      }

      // WalletLoadingService.load(WalletType, String name)
      final walletType = _deserializeWalletType(walletTypeRaw);
      final wallet = await (loadingService as dynamic).load(walletType, name);

      // Update AppStore
      final appStore = getIt.call<dynamic>(instanceName: 'AppStore');
      if (appStore != null) {
        await (appStore as dynamic).changeCurrentWallet(wallet);
      }

      ctx.wallet = wallet;
      ctx.eventBus.emit(
          WalletEvent(WalletEventType.walletOpened, data: {'name': name}));
    } catch (e) {
      ctx.logger.error('Failed to load wallet "$name": $e');
      rethrow;
    }
  }

  /// Try to auto-load the last used wallet from SharedPreferences.
  Future<void> autoLoadCurrentWallet() async {
    try {
      final getIt = _tryGetIt();
      if (getIt == null) return;

      final prefs = getIt.call<dynamic>(instanceName: 'SharedPreferences');
      if (prefs == null) return;

      final name = (prefs as dynamic).getString('current_wallet_name') as String?;
      final typeRaw = (prefs as dynamic).getInt('current_wallet_type') as int?;

      if (name != null && typeRaw != null && ctx.loadWallet != null) {
        await ctx.loadWallet!(name, typeRaw);
      }
    } catch (e) {
      ctx.logger.warn('Failed to auto-load wallet: $e');
    }
  }

  /// Attempt to get the GetIt instance via reflection.
  /// Returns null if GetIt is not available.
  Function? _tryGetIt() {
    try {
      // GetIt.instance.get<T>() — we access it dynamically to avoid
      // a hard import dependency on get_it from this file
      return null; // Placeholder — the entry point wires this directly
    } catch (_) {
      return null;
    }
  }

  dynamic _deserializeWalletType(int raw) {
    // WalletType enum values — imported from cw_core at usage sites
    // This is a simple index-based deserialization
    return raw;
  }
}
