import 'package:cake_headless/dto/address_entry.dart';
import 'package:cake_headless/dto/backup_result.dart';
import 'package:cake_headless/dto/node_info.dart';
import 'package:cake_headless/dto/send_result.dart';
import 'package:cake_headless/dto/swap_quote.dart';
import 'package:cake_headless/dto/swap_status.dart';
import 'package:cake_headless/ports/secure_storage_port.dart';
import 'package:cake_headless/ports/settings_store_port.dart';
import 'package:cake_headless/ports/path_provider_port.dart';
import 'package:cake_headless/ports/asset_loader_port.dart';
import 'package:cake_headless/ports/logger_port.dart';
import 'package:cake_headless/ports/user_interaction_port.dart';
import 'package:cake_headless/events/event_bus.dart';
import 'package:cake_headless/i18n/app_strings.dart';
import 'package:cake_headless/i18n/default_app_strings.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';

/// Dependency-injection context that owns all runtime resources for headless
/// execution. Entry points populate this with real service instances after
/// initialization.
class CakeRuntimeContext {
  final SecureStoragePort secureStorage;
  final SettingsStorePort settings;
  final PathProviderPort pathProvider;
  final AssetLoaderPort assetLoader;
  final LoggerPort logger;
  UserInteractionPort interaction;
  final WalletEventBus eventBus;
  final AppStrings strings;

  /// The currently active wallet.
  WalletBase? wallet;

  /// Whether a wallet is currently loaded.
  bool get hasWallet => wallet != null;

  /// Callback to list all available wallet infos.
  Future<List<WalletInfo>> Function()? listWalletInfos;

  /// Callback to load/open a wallet by name and type.
  Future<void> Function(String name, int walletTypeRaw)? loadWallet;

  /// Callback to send a transaction. Wired by the entry point.
  Future<SendResult> Function(String address, String amount,
      {String? priority})? sendTransaction;

  /// Callback to list configured nodes as DTOs.
  Future<List<NodeInfo>> Function()? listNodes;

  /// Callback to list contacts as DTOs.
  Future<List<AddressEntry>> Function()? listContacts;

  /// Callback to get an exchange quote. Wired to exchange providers when
  /// full DI is available.
  Future<SwapQuote> Function(String from, String to, String amount)?
      getSwapQuote;

  /// Callback to check exchange trade status by trade ID.
  Future<SwapStatus> Function(String tradeId)? getSwapStatus;

  /// Callback to add a node. Returns the created NodeInfo.
  Future<NodeInfo> Function(String uri, String name, bool trusted)? addNode;

  /// Callback to select a node by URI.
  Future<NodeInfo> Function(String uri)? selectNode;

  /// Callback to delete a node by URI.
  Future<void> Function(String uri)? deleteNode;

  /// Callback to add a contact. Returns the created AddressEntry.
  Future<AddressEntry> Function(
      String name, String address, String? currency)? addContact;

  /// Callback to delete a contact by name.
  Future<void> Function(String name)? deleteContact;

  /// Callback to export an encrypted backup to the given path.
  Future<BackupResult> Function(String outputPath)? exportBackup;

  /// Callback to import an encrypted backup from the given path.
  Future<BackupResult> Function(String inputPath)? importBackup;

  /// Runtime mode flags
  bool nonInteractive = false;
  bool autoConfirm = false;
  bool jsonMode = false;
  bool noColor = false;

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
