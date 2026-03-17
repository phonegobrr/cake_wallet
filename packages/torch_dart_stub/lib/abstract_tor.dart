abstract class Tor {
  String? get version;
  void start(final List<String> argv);

  static Future<List<Tor>> getTorList() async {
    // Stub: no native Tor available in headless builds
    return [];
  }

  String toJson();
}
