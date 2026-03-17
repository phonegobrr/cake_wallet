class BalanceSnapshot {
  final String available;
  final String pending;
  final String frozen;
  final String currencyTitle;

  const BalanceSnapshot({
    required this.available,
    required this.pending,
    required this.frozen,
    required this.currencyTitle,
  });

  Map<String, dynamic> toJson() => {
        'available': available,
        'pending': pending,
        'frozen': frozen,
        'currency': currencyTitle,
      };
}
