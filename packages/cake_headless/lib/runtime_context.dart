import 'package:cake_headless/ports/secure_storage_port.dart';
import 'package:cake_headless/ports/settings_store_port.dart';
import 'package:cake_headless/ports/path_provider_port.dart';
import 'package:cake_headless/ports/asset_loader_port.dart';
import 'package:cake_headless/ports/logger_port.dart';
import 'package:cake_headless/ports/user_interaction_port.dart';
import 'package:cake_headless/events/event_bus.dart';
import 'package:cake_headless/i18n/app_strings.dart';
import 'package:cake_headless/i18n/default_app_strings.dart';

class CakeRuntimeContext {
  final SecureStoragePort secureStorage;
  final SettingsStorePort settings;
  final PathProviderPort pathProvider;
  final AssetLoaderPort assetLoader;
  final LoggerPort logger;
  final UserInteractionPort interaction;
  final WalletEventBus eventBus;
  final AppStrings strings;

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
