class SendResult {
  final String txHash;
  final String amount;
  final String address;
  final String fee;

  const SendResult({
    required this.txHash,
    required this.amount,
    required this.address,
    required this.fee,
  });

  Map<String, dynamic> toJson() => {
        'tx_hash': txHash,
        'amount': amount,
        'address': address,
        'fee': fee,
      };
}
