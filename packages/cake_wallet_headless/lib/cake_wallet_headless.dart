import 'package:cake_headless/runtime_context.dart';
import 'package:cake_headless/dto/node_info.dart';
import 'package:cake_headless/dto/address_entry.dart';
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/node.dart';

/// Wire callbacks on [CakeRuntimeContext] that can be satisfied
/// using only cw_core types and Hive box access (no Flutter/GetIt).
///
/// For callbacks that require full Flutter app DI (loadWallet,
/// sendTransaction, etc.), the entry point must wire them directly.
///
/// Usage:
/// ```dart
/// wireHeadlessCallbacks(ctx);
/// // Then wire Flutter-dependent callbacks on ctx if needed
/// ```
void wireHeadlessCallbacks(CakeRuntimeContext ctx) {
  // Wire listNodes from Hive box
  ctx.listNodes ??= () async {
    final box = CakeHive.box<Node>(Node.boxName);
    final wallet = ctx.wallet;
    return box.values
        .where((n) => wallet == null || n.type == wallet.type)
        .map((n) => NodeInfo(
              uri: n.uriRaw,
              name: n.label,
              isActive: false,
              isTrusted: n.trusted,
            ))
        .toList();
  };

  // Wire addNode to Hive box
  ctx.addNode ??= (String uri, String name, bool trusted) async {
    final wallet = ctx.wallet;
    if (wallet == null) {
      throw StateError('Cannot add node: no wallet is open to determine node type');
    }
    final box = CakeHive.box<Node>(Node.boxName);
    final node = Node(
      uri: uri,
      type: wallet.type,
      trusted: trusted,
    )..label = name;
    await box.add(node);
    return NodeInfo(uri: uri, name: name, isActive: false, isTrusted: trusted);
  };

  // Wire deleteNode from Hive box — match by URI AND wallet type to avoid cross-type deletion
  ctx.deleteNode ??= (String uri) async {
    final box = CakeHive.box<Node>(Node.boxName);
    final wallet = ctx.wallet;
    final node = box.values.where((n) =>
        n.uriRaw == uri &&
        (wallet == null || n.type == wallet.type)).firstOrNull;
    if (node != null) {
      await node.delete();
    }
  };

  // Wire connectAndSync
  ctx.connectAndSync ??= () async {
    final wallet = ctx.wallet;
    if (wallet == null) return;
    await wallet.startSync();
  };
}
