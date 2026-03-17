abstract class LoggerPort {
  void info(String message);
  void error(String message, [Object? error, StackTrace? stackTrace]);
  void debug(String message);
  void warn(String message);
}
