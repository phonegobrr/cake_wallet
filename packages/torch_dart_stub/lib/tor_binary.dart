import 'package:torch_dart/abstract_tor.dart';

class TorBinary implements Tor {
  @override
  String? get version => null;

  @override
  void start(List<String> argv) {
    throw UnsupportedError('TorBinary not available in headless builds');
  }

  @override
  String toJson() => '{"type": "binary", "available": false}';

  static Future<List<Tor>> getTorList() async => [];
}
