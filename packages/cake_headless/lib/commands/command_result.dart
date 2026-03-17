class CommandResult<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? errorCode;
  final Map<String, dynamic>? metadata;

  const CommandResult.ok(T this.data, {this.message, this.metadata})
      : success = true,
        errorCode = null;

  const CommandResult.error(this.errorCode, {this.message, this.metadata})
      : success = false,
        data = null;

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) dataSerializer) => {
        'success': success,
        if (data != null) 'data': dataSerializer(data as T),
        if (message != null) 'message': message,
        if (errorCode != null) 'error_code': errorCode,
        if (metadata != null) 'metadata': metadata,
      };
}
