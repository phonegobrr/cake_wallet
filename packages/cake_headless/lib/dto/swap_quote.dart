class SwapQuote {
  final String fromCurrency;
  final String toCurrency;
  final String fromAmount;
  final String toAmount;
  final String provider;
  final String rateId;

  const SwapQuote({
    required this.fromCurrency,
    required this.toCurrency,
    required this.fromAmount,
    required this.toAmount,
    required this.provider,
    required this.rateId,
  });

  Map<String, dynamic> toJson() => {
        'from_currency': fromCurrency,
        'to_currency': toCurrency,
        'from_amount': fromAmount,
        'to_amount': toAmount,
        'provider': provider,
        'rate_id': rateId,
      };
}
