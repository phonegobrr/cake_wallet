class SwapStatus {
  final String tradeId;
  final String status;
  final String fromCurrency;
  final String toCurrency;
  final String? fromAmount;
  final String? toAmount;

  const SwapStatus({
    required this.tradeId,
    required this.status,
    required this.fromCurrency,
    required this.toCurrency,
    this.fromAmount,
    this.toAmount,
  });

  Map<String, dynamic> toJson() => {
        'trade_id': tradeId,
        'status': status,
        'from_currency': fromCurrency,
        'to_currency': toCurrency,
        if (fromAmount != null) 'from_amount': fromAmount,
        if (toAmount != null) 'to_amount': toAmount,
      };
}
