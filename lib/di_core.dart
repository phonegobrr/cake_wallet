import 'package:cake_wallet/anonpay/anonpay_invoice_info.dart';
import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/core/reset_service.dart';
import 'package:cake_wallet/core/secure_storage.dart';
import 'package:cake_wallet/core/trade_monitor.dart';
import 'package:cake_wallet/core/wallet_creation_service.dart';
import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/entities/template.dart';
import 'package:cake_wallet/entities/transaction_description.dart';
import 'package:cake_wallet/exchange/exchange_template.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/order/order.dart';
import 'package:cake_wallet/store/anonpay/anonpay_transactions_store.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/authentication_store.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/dashboard/order_filter_store.dart';
import 'package:cake_wallet/store/dashboard/orders_store.dart';
import 'package:cake_wallet/store/dashboard/payjoin_transactions_store.dart';
import 'package:cake_wallet/store/dashboard/trade_filter_store.dart';
import 'package:cake_wallet/store/dashboard/trades_store.dart';
import 'package:cake_wallet/store/dashboard/transaction_filter_store.dart';
import 'package:cake_wallet/store/node_list_store.dart';
import 'package:cake_wallet/store/seed_settings_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/store/templates/exchange_template_store.dart';
import 'package:cake_wallet/store/templates/send_template_store.dart';
import 'package:cake_wallet/store/wallet_list_store.dart';
import 'package:cake_wallet/themes/core/theme_store.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/payjoin_session.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Registers all platform-agnostic services, stores, and core factories.
/// Called by both the Flutter app's [setup()] and headless initialization.
/// Does NOT register pages, widgets, BottomSheetService, or WalletKitService.
Future<void> setupCore({
  required GetIt getIt,
  required Box<Node> nodeSource,
  required Box<Node> powNodeSource,
  required Box<Contact> contactSource,
  required Box<Trade> tradesSource,
  required Box<Order> ordersSource,
  required Box<Template> templates,
  required Box<ExchangeTemplate> exchangeTemplates,
  required Box<TransactionDescription> transactionDescriptionBox,
  required Box<AnonpayInvoiceInfo> anonpayInvoiceInfoSource,
  required Box<UnspentCoinsInfo> unspentCoinsInfoSource,
  required Box<PayjoinSession> payjoinSessionSource,
  required SecureStorage secureStorage,
  required SettingsStore settingsStore,
  required ThemeStore themeStore,
  SharedPreferences? sharedPreferences,
}) async {
  if (!getIt.isRegistered<SecureStorage>()) {
    getIt.registerSingleton<SecureStorage>(secureStorage);
  }

  if (!getIt.isRegistered<SharedPreferences>()) {
    if (sharedPreferences != null) {
      getIt.registerSingleton<SharedPreferences>(sharedPreferences);
    } else {
      getIt.registerSingletonAsync<SharedPreferences>(
          () => SharedPreferences.getInstance());
    }
  }

  if (!getIt.isRegistered<ThemeStore>()) {
    getIt.registerSingleton<ThemeStore>(themeStore);
  }

  getIt.registerFactory<Box<Node>>(() => nodeSource);
  getIt.registerFactory<Box<Node>>(() => powNodeSource,
      instanceName: Node.boxName + 'pow');

  getIt.registerSingleton(AuthenticationStore());
  getIt.registerSingleton<WalletListStore>(WalletListStore());
  getIt.registerSingleton(NodeListStoreBase.instance);
  getIt.registerSingleton<SettingsStore>(settingsStore);

  getIt.registerSingleton<AppStore>(AppStore(
    authenticationStore: getIt.get<AuthenticationStore>(),
    walletList: getIt.get<WalletListStore>(),
    settingsStore: getIt.get<SettingsStore>(),
    nodeListStore: getIt.get<NodeListStore>(),
    themeStore: getIt.get<ThemeStore>(),
  ));

  getIt.registerSingleton<TradesStore>(
      TradesStore(tradesSource: tradesSource, appStore: getIt.get<AppStore>()));
  getIt.registerSingleton<OrdersStore>(OrdersStore(
      ordersSource: ordersSource,
      settingsStore: getIt.get<SettingsStore>()));
  getIt.registerFactory(
      () => PayjoinTransactionsStore(payjoinSessionSource: payjoinSessionSource));
  getIt.registerSingleton<TradeFilterStore>(TradeFilterStore());
  getIt.registerSingleton<OrderFilterStore>(OrderFilterStore());
  getIt.registerSingleton<TransactionFilterStore>(
      TransactionFilterStore(getIt.get<AppStore>()));
  getIt.registerSingleton<FiatConversionStore>(FiatConversionStore());
  getIt.registerSingleton<SendTemplateStore>(
      SendTemplateStore(templateSource: templates));
  getIt.registerSingleton<ExchangeTemplateStore>(
      ExchangeTemplateStore(templateSource: exchangeTemplates));
  getIt.registerSingleton<AnonpayTransactionsStore>(
      AnonpayTransactionsStore(anonpayInvoiceInfoSource: anonpayInvoiceInfoSource));
  getIt.registerSingleton<SeedSettingsStore>(SeedSettingsStore());

  getIt.registerFactory<KeyService>(
      () => KeyService(getIt.get<SecureStorage>()));

  getIt.registerFactoryParam<WalletCreationService, WalletType, void>(
      (type, _) => WalletCreationService(
            initialType: type,
            keyService: getIt.get<KeyService>(),
            sharedPreferences: getIt.get<SharedPreferences>(),
            settingsStore: getIt.get<SettingsStore>(),
          ));

  getIt.registerFactory<WalletLoadingService>(() => WalletLoadingService(
      getIt.get<SharedPreferences>(),
      getIt.get<KeyService>(),
      (WalletType type) => getIt.get<WalletService>(param1: type)));

  final walletList = await WalletInfo.getAll();

  getIt.registerFactory<AuthService>(() => AuthService(
        secureStorage: getIt.get<SecureStorage>(),
        sharedPreferences: getIt.get<SharedPreferences>(),
        settingsStore: getIt.get<SettingsStore>(),
        authenticationStore: getIt.get<AuthenticationStore>(),
        appStore: getIt.get<AppStore>(),
        resetService: getIt.get<ResetService>(),
        walletList: walletList,
      ));

  getIt.registerFactory<ResetService>(() => ResetService(
        secureStorage: getIt.get<SecureStorage>(),
        authenticationStore: getIt.get<AuthenticationStore>(),
        settingsStore: getIt.get<SettingsStore>(),
      ));

  getIt.registerSingleton(TradeMonitor(
    tradesStore: getIt.get<TradesStore>(),
    trades: tradesSource,
    appStore: getIt.get<AppStore>(),
    preferences: getIt.get<SharedPreferences>(),
  ));
}
