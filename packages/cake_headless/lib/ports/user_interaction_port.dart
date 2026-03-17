abstract class UserInteractionPort {
  Future<bool> confirm(String message);
  Future<String?> promptText(String message, {bool obscure = false});
  Future<int?> pickOption(String message, List<String> options);
}
