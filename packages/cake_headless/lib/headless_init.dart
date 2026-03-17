import 'package:cw_core/address_info.dart';
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/db/sqlite.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/hive_type_ids.dart';
import 'package:cw_core/mweb_utxo.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/payjoin_session.dart';
import 'package:cw_core/root_dir.dart';
import 'package:cw_core/secure_storage.dart';
import 'package:cw_core/spl_token.dart';
import 'package:cw_core/tron_token.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:get_it/get_it.dart';

/// Minimal headless initialization using only cw_core types (no Flutter).
///
/// Initializes Hive with cw_core adapters, opens SQLite for WalletInfo,
/// and registers SecureStorage in GetIt.
///
/// For full app initialization (Contacts, Trades, Templates, Settings, etc.),
/// use the Flutter app's `initializeHeadless()` in `lib/headless_init.dart`
/// which calls `setupCore()` and opens all Hive boxes.
///
/// This minimal init enables:
/// - wallet.list (via WalletInfo.getAll from SQLite)
/// - Node box operations
/// - SecureStorage in GetIt
Future<void> initializeHeadlessCore({
  required String dataDir,
  required SecureStorage secureStorage,
}) async {
  setRootDirOverride(dataDir);

  // Initialize Hive
  CakeHive.init(dataDir);

  // Register cw_core adapters (idempotent)
  _registerCoreAdapters();

  // Initialize SQLite (for WalletInfo)
  await initDb();

  // Open cw_core Hive boxes
  await CakeHive.openBox<Node>(Node.boxName);
  await CakeHive.openBox<Node>('${Node.boxName}pow');
  await CakeHive.openBox<UnspentCoinsInfo>(UnspentCoinsInfo.boxName);
  await CakeHive.openBox<PayjoinSession>(PayjoinSession.boxName);

  // Register SecureStorage in GetIt
  final di = GetIt.instance;
  if (!di.isRegistered<SecureStorage>()) {
    di.registerSingleton<SecureStorage>(secureStorage);
  }
}

void _registerCoreAdapters() {
  if (!CakeHive.isAdapterRegistered(Node.typeId)) {
    CakeHive.registerAdapter(NodeAdapter());
  }
  if (!CakeHive.isAdapterRegistered(AddressInfo.typeId)) {
    CakeHive.registerAdapter(AddressInfoAdapter());
  }
  if (!CakeHive.isAdapterRegistered(WALLET_TYPE_TYPE_ID)) {
    CakeHive.registerAdapter(WalletTypeAdapter());
  }
  if (!CakeHive.isAdapterRegistered(UnspentCoinsInfo.typeId)) {
    CakeHive.registerAdapter(UnspentCoinsInfoAdapter());
  }
  if (!CakeHive.isAdapterRegistered(MwebUtxo.typeId)) {
    CakeHive.registerAdapter(MwebUtxoAdapter());
  }
  if (!CakeHive.isAdapterRegistered(PayjoinSession.typeId)) {
    CakeHive.registerAdapter(PayjoinSessionAdapter());
  }
  if (!CakeHive.isAdapterRegistered(Erc20Token.typeId)) {
    CakeHive.registerAdapter(Erc20TokenAdapter());
  }
  if (!CakeHive.isAdapterRegistered(SPLToken.typeId)) {
    CakeHive.registerAdapter(SPLTokenAdapter());
  }
  if (!CakeHive.isAdapterRegistered(TronToken.typeId)) {
    CakeHive.registerAdapter(TronTokenAdapter());
  }
}
