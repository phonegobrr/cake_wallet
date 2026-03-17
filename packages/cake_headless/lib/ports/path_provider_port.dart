abstract class PathProviderPort {
  Future<String> getAppDir();
  Future<String> getCacheDir();
}
