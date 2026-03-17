class TransactionSummary {
  final String id;
  final String amount;
  final String amountFormatted;
  final String fee;
  final bool isIncoming;
  final bool isPending;
  final DateTime date;
  final String dateFormatted;
  final int confirmations;
  final String? address;

  const TransactionSummary({
    required this.id,
    required this.amount,
    required this.amountFormatted,
    required this.fee,
    required this.isIncoming,
    required this.isPending,
    required this.date,
    required this.dateFormatted,
    required this.confirmations,
    this.address,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'amount_formatted': amountFormatted,
        'fee': fee,
        'is_incoming': isIncoming,
        'is_pending': isPending,
        'date': date.toIso8601String(),
        'date_formatted': dateFormatted,
        'confirmations': confirmations,
        if (address != null) 'address': address,
      };
}
