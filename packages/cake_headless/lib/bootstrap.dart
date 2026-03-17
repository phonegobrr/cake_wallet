import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_headless/commands/wallet_commands.dart';
import 'package:cake_headless/commands/send_commands.dart';
import 'package:cake_headless/commands/receive_commands.dart';
import 'package:cake_headless/commands/history_commands.dart';
import 'package:cake_headless/commands/node_commands.dart';
import 'package:cake_headless/commands/settings_commands.dart';
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

  // Register all commands
  bus.register(ListWalletsCommand());
  bus.register(GetBalanceCommand());
  bus.register(GetReceiveAddressCommand());
  bus.register(ListTransactionsCommand());
  bus.register(ListNodesCommand());
  bus.register(ListSettingsCommand());
  bus.register(GetSyncStatusCommand());

  return bus;
}
