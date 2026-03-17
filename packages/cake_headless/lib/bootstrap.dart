import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_headless/commands/wallet_commands.dart';
import 'package:cake_headless/commands/send_commands.dart';
import 'package:cake_headless/commands/receive_commands.dart';
import 'package:cake_headless/commands/history_commands.dart';
import 'package:cake_headless/commands/node_commands.dart';
import 'package:cake_headless/commands/settings_commands.dart';
import 'package:cake_headless/commands/swap_commands.dart';
import 'package:cake_headless/commands/contact_commands.dart';
import 'package:cake_headless/commands/backup_commands.dart';
import 'package:cake_headless/commands/tor_commands.dart';
import 'package:cake_headless/commands/unsupported_commands.dart';
import 'package:cake_headless/runtime_context.dart';
import 'package:cake_headless/services/wallet_lock.dart';
import 'package:cw_core/root_dir.dart';

/// Bootstrap the headless runtime: set up paths, lock wallet dir, register commands.
Future<CommandBus> bootstrap(CakeRuntimeContext ctx) async {
  final appDir = await ctx.pathProvider.getAppDir();
  setRootDirOverride(appDir);

  final lock = WalletLock();
  await lock.acquire(appDir);

  final bus = CommandBus(ctx);

  // Wallet
  bus.register(ListWalletsCommand());
  bus.register(GetBalanceCommand());
  bus.register(OpenWalletCommand());
  bus.register(CloseWalletCommand());
  bus.register(GetWalletSeedCommand());
  bus.register(GetWalletKeysCommand());
  bus.register(RescanWalletCommand());

  // Send / Receive
  bus.register(SendCommand());
  bus.register(GetReceiveAddressCommand());
  bus.register(ListAddressesCommand());
  bus.register(GenerateNewAddressCommand());
  bus.register(GetReceiveUriCommand());

  // History
  bus.register(GetTransactionDetailsCommand());
  bus.register(ListTransactionsCommand());

  // Nodes
  bus.register(ListNodesCommand());
  bus.register(AddNodeCommand());
  bus.register(TestNodeCommand());
  bus.register(SelectNodeCommand());
  bus.register(DeleteNodeCommand());

  // Settings & Sync
  bus.register(ListSettingsCommand());
  bus.register(GetSettingCommand());
  bus.register(SetSettingCommand());
  bus.register(GetSyncStatusCommand());

  // Exchange / Swap
  bus.register(CreateSwapCommand());
  bus.register(GetSwapQuoteCommand());
  bus.register(GetSwapStatusCommand());

  // Contacts
  bus.register(ListContactsCommand());
  bus.register(AddContactCommand());
  bus.register(DeleteContactCommand());

  // Backup
  bus.register(ExportBackupCommand());
  bus.register(VerifyBackupCommand());
  bus.register(ImportBackupCommand());

  // Tor
  bus.register(TorStatusCommand());
  bus.register(TorEnableCommand());
  bus.register(TorDisableCommand());

  // Unsupported platform stubs
  for (final cmd in createUnsupportedCommands()) {
    bus.register(cmd);
  }

  return bus;
}
