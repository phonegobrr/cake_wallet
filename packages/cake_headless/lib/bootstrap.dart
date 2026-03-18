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
import 'package:cake_headless/commands/coin_commands.dart';
import 'package:cake_headless/commands/token_commands.dart';
import 'package:cake_headless/commands/fiat_commands.dart';
import 'package:cake_headless/commands/unsupported_commands.dart';
import 'package:cake_headless/runtime_context.dart';
import 'package:cake_headless/services/wallet_lock.dart';
import 'package:cw_core/root_dir.dart';

/// Register all commands on a CommandBus without side effects.
/// Useful for manifest generation and testing without acquiring locks.
CommandBus registerAllCommands(CakeRuntimeContext ctx) {
  final bus = CommandBus(ctx);
  _registerCommands(bus);
  return bus;
}

/// Bootstrap the headless runtime: set up paths, lock wallet dir, register commands.
/// Set [skipLock] to true for read-only commands that don't need exclusive access.
Future<CommandBus> bootstrap(CakeRuntimeContext ctx, {bool skipLock = false}) async {
  final appDir = await ctx.pathProvider.getAppDir();
  setRootDirOverride(appDir);

  if (!skipLock) {
    final lock = WalletLock();
    await lock.acquire(appDir);
    ctx.walletLock = lock;
  }

  final bus = registerAllCommands(ctx);
  return bus;
}

void _registerCommands(CommandBus bus) {
  // Wallet
  bus.register(ListWalletsCommand());
  bus.register(GetBalanceCommand());
  bus.register(OpenWalletCommand());
  bus.register(CloseWalletCommand());
  bus.register(GetWalletSeedCommand());
  bus.register(GetWalletKeysCommand());
  bus.register(RescanWalletCommand());
  bus.register(CreateWalletCommand());
  bus.register(RestoreWalletSeedCommand());
  bus.register(DeleteWalletCommand());
  bus.register(RenameWalletCommand());
  bus.register(RestoreWalletKeysCommand());
  bus.register(SyncStartCommand());
  bus.register(SyncStopCommand());
  bus.register(SignMessageCommand());
  bus.register(VerifyMessageCommand());

  // Send / Receive
  bus.register(SendPreviewCommand());
  bus.register(SendMaxCommand());
  bus.register(SendAllCommand());
  bus.register(SendCommitCommand());
  bus.register(SendCommand());
  bus.register(GetReceiveAddressCommand());
  bus.register(ListAddressesCommand());
  bus.register(GenerateNewAddressCommand());
  bus.register(RotateAddressCommand());
  bus.register(LabelAddressCommand());
  bus.register(HideAddressCommand());
  bus.register(UnhideAddressCommand());
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
  bus.register(EditNodeCommand());
  bus.register(ResetNodesCommand());

  // Settings & Sync
  bus.register(ListSettingsCommand());
  bus.register(GetSettingCommand());
  bus.register(SetSettingCommand());
  bus.register(GetSyncStatusCommand());

  // Exchange / Swap
  bus.register(CreateSwapCommand());
  bus.register(GetSwapQuoteCommand());
  bus.register(GetSwapStatusCommand());
  bus.register(SwapProvidersCommand());
  bus.register(SwapCancelCommand());

  // Contacts
  bus.register(ListContactsCommand());
  bus.register(AddContactCommand());
  bus.register(DeleteContactCommand());
  bus.register(EditContactCommand());

  // Backup
  bus.register(ExportBackupCommand());
  bus.register(VerifyBackupCommand());
  bus.register(ImportBackupCommand());

  // Tor
  bus.register(TorStatusCommand());
  bus.register(TorEnableCommand());
  bus.register(TorDisableCommand());

  // Coins / Tokens / Fiat
  bus.register(ListCoinsCommand());
  bus.register(FreezeCoinCommand());
  bus.register(UnfreezeCoinCommand());
  bus.register(ListTokensCommand());
  bus.register(AddTokenCommand());
  bus.register(RemoveTokenCommand());
  bus.register(FiatConvertCommand());

  // Unsupported platform stubs
  for (final cmd in createUnsupportedCommands()) {
    bus.register(cmd);
  }
}
