import 'package:torch_dart/abstract_tor.dart';

class TorLibrary implements Tor {
  @override
  String? get version => null;

  @override
  void start(List<String> argv) {
    throw UnsupportedError('TorLibrary not available in headless builds');
  }

  @override
  String toJson() => '{"type": "library", "available": false}';

  static Future<List<Tor>> getTorList() async => [];
}
