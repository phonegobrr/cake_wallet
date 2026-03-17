class WalletSummary {
  final String name;
  final int typeRaw;
  final String typeName;
  final bool isActive;

  const WalletSummary({
    required this.name,
    required this.typeRaw,
    required this.typeName,
    required this.isActive,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': typeName,
        'type_raw': typeRaw,
        'is_active': isActive,
      };
}
