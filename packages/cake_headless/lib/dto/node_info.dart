class NodeInfo {
  final String uri;
  final String? name;
  final bool isActive;
  final bool isTrusted;

  const NodeInfo({
    required this.uri,
    this.name,
    required this.isActive,
    required this.isTrusted,
  });

  Map<String, dynamic> toJson() => {
        'uri': uri,
        if (name != null) 'name': name,
        'is_active': isActive,
        'is_trusted': isTrusted,
      };
}
