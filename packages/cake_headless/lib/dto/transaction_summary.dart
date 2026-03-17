class TransactionSummary {
  final String id;
  final String amount;
  final String fee;
  final bool isIncoming;
  final bool isPending;
  final String dateFormatted;
  final int confirmations;
  final String? address;

  const TransactionSummary({
    required this.id,
    required this.amount,
    required this.fee,
    required this.isIncoming,
    required this.isPending,
    required this.dateFormatted,
    required this.confirmations,
    this.address,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'fee': fee,
        'is_incoming': isIncoming,
        'is_pending': isPending,
        'date': dateFormatted,
        'confirmations': confirmations,
        if (address != null) 'address': address,
      };
}
