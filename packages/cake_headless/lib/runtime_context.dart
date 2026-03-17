import 'package:cake_headless/dto/address_entry.dart';
import 'package:cake_headless/dto/node_info.dart';
import 'package:cake_headless/ports/secure_storage_port.dart';
import 'package:cake_headless/ports/settings_store_port.dart';
import 'package:cake_headless/ports/path_provider_port.dart';
import 'package:cake_headless/ports/asset_loader_port.dart';
import 'package:cake_headless/ports/logger_port.dart';
import 'package:cake_headless/ports/user_interaction_port.dart';
import 'package:cake_headless/events/event_bus.dart';
import 'package:cake_headless/i18n/app_strings.dart';
import 'package:cake_headless/i18n/default_app_strings.dart';

/// Dependency-injection context that owns all runtime resources for headless
/// execution. Entry points populate this with real service instances after
/// initialization.
///
/// The [wallet], [listWalletInfos], and [loadWallet] fields are typed as
/// dynamic/Function to avoid importing cw_core's hive-dependent types at this
/// layer. Commands cast them to the concrete cw_core types they need.
class CakeRuntimeContext {
  final SecureStoragePort secureStorage;
  final SettingsStorePort settings;
  final PathProviderPort pathProvider;
  final AssetLoaderPort assetLoader;
  final LoggerPort logger;
  final UserInteractionPort interaction;
  final WalletEventBus eventBus;
  final AppStrings strings;

  /// The currently active wallet (typed as WalletBase at usage sites).
  /// Populated by the entry point after initialization.
  dynamic wallet;

  /// Callback to list all available wallet infos.
  /// Returns `List<WalletInfo>` — typed as dynamic to avoid hive import chain.
  Future<List<dynamic>> Function()? listWalletInfos;

  /// Callback to load/open a wallet by name and type.
  Future<void> Function(String name, int walletTypeRaw)? loadWallet;

  /// Callback to list configured nodes as DTOs.
  Future<List<NodeInfo>> Function()? listNodes;

  /// Callback to list contacts as DTOs.
  Future<List<AddressEntry>> Function()? listContacts;

  CakeRuntimeContext({
    required this.secureStorage,
    required this.settings,
    required this.pathProvider,
    required this.assetLoader,
    required this.logger,
    required this.interaction,
    WalletEventBus? eventBus,
    AppStrings? strings,
  })  : eventBus = eventBus ?? WalletEventBus(),
        strings = strings ?? DefaultAppStrings();

  void dispose() {
    eventBus.dispose();
  }
}
