import 'package:cw_core/anonpay_invoice_info.dart';
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/contact.dart';
import 'package:cw_core/db/sqlite.dart';
import 'package:cw_core/exchange_template.dart';
import 'package:cw_core/generate_name.dart' show setAssetLoader;
import 'package:cw_core/haven_seed_store.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/order.dart';
import 'package:cw_core/payjoin_session.dart';
import 'package:cw_core/register_adapters.dart';
import 'package:cw_core/root_dir.dart';
import 'package:cw_core/secure_storage.dart';
import 'package:cw_core/template.dart';
import 'package:cw_core/trade.dart';
import 'package:cw_core/transaction_description.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/utils/tor/disabled.dart';
import 'package:cw_core/wallet_info.dart' show performHiveMigration;
import 'package:cake_headless/ports/asset_loader_port.dart';
import 'package:get_it/get_it.dart';

/// Headless initialization using cw_core types (no Flutter).
///
/// Initializes Hive with all shared adapters, opens boxes for entities
/// that have been extracted to cw_core, initializes SQLite for WalletInfo,
/// and registers SecureStorage in GetIt.
Future<void> initializeHeadlessCore({
  required String dataDir,
  required SecureStorage secureStorage,
  AssetLoaderPort? assetLoader,
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

  // Run Hive→SQLite migration for legacy WalletInfo entries
  await performHiveMigration();

  // Open cw_core Hive boxes
  await CakeHive.openBox<Node>(Node.boxName);
  await CakeHive.openBox<Node>('${Node.boxName}pow');
  await CakeHive.openBox<UnspentCoinsInfo>(UnspentCoinsInfo.boxName);
  await CakeHive.openBox<PayjoinSession>(PayjoinSession.boxName);
  // Extracted model boxes (Section 3.2)
  await CakeHive.openBox<Contact>(Contact.boxName);
  await CakeHive.openBox<Trade>(Trade.boxName);
  await CakeHive.openBox<Template>(Template.boxName);
  await CakeHive.openBox<ExchangeTemplate>(ExchangeTemplate.boxName);
  await CakeHive.openBox<Order>(Order.boxName);
  await CakeHive.openBox<TransactionDescription>(TransactionDescription.boxName);
  await CakeHive.openBox<AnonpayInvoiceInfo>(AnonpayInvoiceInfo.boxName);
  await CakeHive.openBox<HavenSeedStore>(HavenSeedStore.boxName);

  // Register SecureStorage in GetIt
  final di = GetIt.instance;
  if (!di.isRegistered<SecureStorage>()) {
    di.registerSingleton<SecureStorage>(secureStorage);
  }

  // Wire asset loader for cw_core/generate_name.dart
  if (assetLoader != null) {
    setAssetLoader((path) => assetLoader.loadString(path));
  }
}
