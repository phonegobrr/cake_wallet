import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/db/sqlite.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/payjoin_session.dart';
import 'package:cw_core/register_adapters.dart';
import 'package:cw_core/root_dir.dart';
import 'package:cw_core/secure_storage.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/utils/tor/disabled.dart';
import 'package:get_it/get_it.dart';

/// Headless initialization using cw_core types (no Flutter).
///
/// Initializes Hive with all shared adapters, opens boxes for entities
/// that have been extracted to cw_core, initializes SQLite for WalletInfo,
/// and registers SecureStorage in GetIt.
Future<void> initializeHeadlessCore({
  required String dataDir,
  required SecureStorage secureStorage,
}) async {
  setRootDirOverride(dataDir);

  // Initialize CakeTor with disabled implementation for headless mode
  CakeTor.instance ??= CakeTorDisabled();

  // Initialize Hive
  CakeHive.init(dataDir);

  // Register all shared cw_core adapters (idempotent)
  registerCoreHiveAdapters();

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
