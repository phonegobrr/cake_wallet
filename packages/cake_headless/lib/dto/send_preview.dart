class SendPreview {
  final String amount;
  final String fee;
  final String address;
  final String total;

  const SendPreview({
    required this.amount,
    required this.fee,
    required this.address,
    required this.total,
  });

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'fee': fee,
        'address': address,
        'total': total,
      };
}
