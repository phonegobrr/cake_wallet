class BalanceSnapshot {
  final String available;
  final String pending;
  final String frozen;
  final String currencyTitle;
  final String? availableFormatted;
  final String? pendingFormatted;
  final String? frozenFormatted;

  const BalanceSnapshot({
    required this.available,
    required this.pending,
    required this.frozen,
    required this.currencyTitle,
    this.availableFormatted,
    this.pendingFormatted,
    this.frozenFormatted,
  });

  Map<String, dynamic> toJson() => {
        'available': available,
        'pending': pending,
        'frozen': frozen,
        'currency': currencyTitle,
        if (availableFormatted != null) 'available_formatted': availableFormatted,
        if (pendingFormatted != null) 'pending_formatted': pendingFormatted,
        if (frozenFormatted != null) 'frozen_formatted': frozenFormatted,
      };
}
