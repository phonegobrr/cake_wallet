abstract class AssetLoaderPort {
  Future<String> loadString(String path);
  Future<List<int>> loadBytes(String path);
}
