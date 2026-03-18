import 'package:cw_core/utils/tor/abstract.dart';

class CakeTorDisabled implements CakeTorInstance {
  @override
  bool get bootstrapped => false;

  @override
  bool get enabled => false;

  @override
  int get port => -1;

  @override
  Future<void> start() async {
    // No-op: Tor not available on this platform
  }

  @override
  bool get started => false;

  @override
  Future<void> stop() async {
    // No-op: Tor not available on this platform
  }

  @override
  String toString() {
    return """
CakeTorDisabled(
  port: $port,
  started: $started,
  bootstrapped: $bootstrapped,
  enabled: $enabled,
)
""";
  }
}