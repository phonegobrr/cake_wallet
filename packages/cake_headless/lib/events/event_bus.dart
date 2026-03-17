import 'dart:async';

import 'package:cake_headless/events/wallet_event.dart';

class WalletEventBus {
  final _controller = StreamController<WalletEvent>.broadcast();

  Stream<WalletEvent> get events => _controller.stream;

  Stream<WalletEvent> on(WalletEventType type) =>
      events.where((e) => e.type == type);

  void emit(WalletEvent event) => _controller.add(event);

  void dispose() => _controller.close();
}
