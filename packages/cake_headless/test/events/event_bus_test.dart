import 'package:cake_headless/events/event_bus.dart';
import 'package:cake_headless/events/wallet_event.dart';
import 'package:test/test.dart';

void main() {
  group('WalletEventBus', () {
    late WalletEventBus bus;

    setUp(() => bus = WalletEventBus());
    tearDown(() => bus.dispose());

    test('emits events to listeners', () async {
      final events = <WalletEvent>[];
      bus.events.listen(events.add);

      bus.emit(WalletEvent(WalletEventType.balanceChanged));
      bus.emit(WalletEvent(WalletEventType.syncStatusChanged));

      await Future.delayed(Duration.zero);
      expect(events, hasLength(2));
      expect(events[0].type, WalletEventType.balanceChanged);
      expect(events[1].type, WalletEventType.syncStatusChanged);
    });

    test('filters events by type', () async {
      final balanceEvents = <WalletEvent>[];
      bus.on(WalletEventType.balanceChanged).listen(balanceEvents.add);

      bus.emit(WalletEvent(WalletEventType.balanceChanged));
      bus.emit(WalletEvent(WalletEventType.syncStatusChanged));
      bus.emit(WalletEvent(WalletEventType.balanceChanged));

      await Future.delayed(Duration.zero);
      expect(balanceEvents, hasLength(2));
    });

    test('events carry data', () async {
      final events = <WalletEvent>[];
      bus.events.listen(events.add);

      bus.emit(WalletEvent(WalletEventType.balanceChanged, data: {'amount': '1.5'}));

      await Future.delayed(Duration.zero);
      expect(events.first.data['amount'], '1.5');
    });
  });
}
