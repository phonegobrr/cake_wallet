import 'package:cake_wallet/anonpay/anonpay_invoice_info.dart';
import 'package:cake_wallet/core/secure_storage.dart';
import 'package:cake_wallet/di_core.dart';
import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/entities/default_settings_migration.dart';
import 'package:cake_wallet/entities/get_encryption_key.dart';
import 'package:cake_wallet/entities/haven_seed_store.dart';
import 'package:cake_wallet/entities/template.dart';
import 'package:cake_wallet/entities/transaction_description.dart';
import 'package:cake_wallet/exchange/exchange_template.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/order/order.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/core/theme_store.dart';
import 'package:cw_core/address_info.dart';
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/db/sqlite.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/hive_type_ids.dart';
import 'package:cw_core/mweb_utxo.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/payjoin_session.dart';
import 'package:cw_core/root_dir.dart';
import 'package:cw_core/spl_token.dart';
import 'package:cw_core/tron_token.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Headless initialization — no Flutter binding required.
/// Used by TUI, CLI, MCP, and API server entry points.
///
/// Initializes Hive, opens all required boxes, runs migrations,
/// then calls [setupCore] for service registration.
Future<void> initializeHeadless({
  required String dataDir,
  required SecureStorage secureStorage,
  GetIt? getItInstance,
}) async {
  final di = getItInstance ?? GetIt.instance;
  setRootDirOverride(dataDir);

  // Initialize Hive
  CakeHive.init(dataDir);

  // Register adapters (idempotent)
  _registerAdapters();

  // Initialize SQLite
  await initDb();

  // Open encrypted boxes
  final transactionDescriptionsBoxKey = await getEncryptionKey(
      secureStorage: secureStorage,
      forKey: TransactionDescription.boxKey);
  final tradesBoxKey = await getEncryptionKey(
      secureStorage: secureStorage, forKey: Trade.boxKey);
  final ordersBoxKey = await getEncryptionKey(
      secureStorage: secureStorage, forKey: Order.boxKey);
  final havenSeedStoreBoxKey = await getEncryptionKey(
      secureStorage: secureStorage, forKey: HavenSeedStore.boxKey);

  // Open boxes
  final contacts = await CakeHive.openBox<Contact>(Contact.boxName);
  final nodes = await CakeHive.openBox<Node>(Node.boxName);
  final powNodes = await CakeHive.openBox<Node>(Node.boxName + 'pow');
  final transactionDescriptions =
      await CakeHive.openBox<TransactionDescription>(
          TransactionDescription.boxName,
          encryptionKey: transactionDescriptionsBoxKey);
  final trades = await CakeHive.openBox<Trade>(Trade.boxName,
      encryptionKey: tradesBoxKey);
  final orders = await CakeHive.openBox<Order>(Order.boxName,
      encryptionKey: ordersBoxKey);
  final templates = await CakeHive.openBox<Template>(Template.boxName);
  final exchangeTemplates =
      await CakeHive.openBox<ExchangeTemplate>(ExchangeTemplate.boxName);
  final anonpayInvoiceInfo =
      await CakeHive.openBox<AnonpayInvoiceInfo>(AnonpayInvoiceInfo.boxName);
  final unspentCoinsInfoSource =
      await CakeHive.openBox<UnspentCoinsInfo>(UnspentCoinsInfo.boxName);
  final payjoinSessionSource =
      await CakeHive.openBox<PayjoinSession>(PayjoinSession.boxName);

  // Haven seed store
  await CakeHive.openBox<HavenSeedStore>(HavenSeedStore.boxName,
      encryptionKey: havenSeedStoreBoxKey);

  // Run migrations
  await performHiveMigration();
  final sharedPreferences = await SharedPreferences.getInstance();
  await defaultSettingsMigration(
    secureStorage: secureStorage,
    version: 61,
    sharedPreferences: sharedPreferences,
    contactSource: contacts,
    tradeSource: trades,
    nodes: nodes,
    powNodes: powNodes,
    havenSeedStore:
        await CakeHive.openBox<HavenSeedStore>(HavenSeedStore.boxName,
            encryptionKey: havenSeedStoreBoxKey),
  );

  // Load settings for headless mode
  final settingsStore = await SettingsStoreBase.loadForHeadless(
    sharedPreferences: sharedPreferences,
    secureStorage: secureStorage,
    nodeSource: nodes,
    powNodeSource: powNodes,
  );

  // ThemeStore can be instantiated without Flutter binding
  final themeStore = ThemeStore();

  // Register core services
  await setupCore(
    getIt: di,
    nodeSource: nodes,
    powNodeSource: powNodes,
    contactSource: contacts,
    tradesSource: trades,
    ordersSource: orders,
    templates: templates,
    exchangeTemplates: exchangeTemplates,
    transactionDescriptionBox: transactionDescriptions,
    anonpayInvoiceInfoSource: anonpayInvoiceInfo,
    unspentCoinsInfoSource: unspentCoinsInfoSource,
    payjoinSessionSource: payjoinSessionSource,
    secureStorage: secureStorage,
    settingsStore: settingsStore,
    themeStore: themeStore,
  );
}

void _registerAdapters() {
  if (!CakeHive.isAdapterRegistered(Contact.typeId)) {
    CakeHive.registerAdapter(ContactAdapter());
  }
  if (!CakeHive.isAdapterRegistered(Node.typeId)) {
    CakeHive.registerAdapter(NodeAdapter());
  }
  if (!CakeHive.isAdapterRegistered(TransactionDescription.typeId)) {
    CakeHive.registerAdapter(TransactionDescriptionAdapter());
  }
  if (!CakeHive.isAdapterRegistered(Trade.typeId)) {
    CakeHive.registerAdapter(TradeAdapter());
  }
  if (!CakeHive.isAdapterRegistered(AddressInfo.typeId)) {
    CakeHive.registerAdapter(AddressInfoAdapter());
  }
  if (!CakeHive.isAdapterRegistered(WALLET_TYPE_TYPE_ID)) {
    CakeHive.registerAdapter(WalletTypeAdapter());
  }
  if (!CakeHive.isAdapterRegistered(Template.typeId)) {
    CakeHive.registerAdapter(TemplateAdapter());
  }
  if (!CakeHive.isAdapterRegistered(ExchangeTemplate.typeId)) {
    CakeHive.registerAdapter(ExchangeTemplateAdapter());
  }
  if (!CakeHive.isAdapterRegistered(Order.typeId)) {
    CakeHive.registerAdapter(OrderAdapter());
  }
  if (!CakeHive.isAdapterRegistered(UnspentCoinsInfo.typeId)) {
    CakeHive.registerAdapter(UnspentCoinsInfoAdapter());
  }
  if (!CakeHive.isAdapterRegistered(AnonpayInvoiceInfo.typeId)) {
    CakeHive.registerAdapter(AnonpayInvoiceInfoAdapter());
  }
  if (!CakeHive.isAdapterRegistered(HavenSeedStore.typeId)) {
    CakeHive.registerAdapter(HavenSeedStoreAdapter());
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
