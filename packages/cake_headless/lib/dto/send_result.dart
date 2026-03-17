class SendResult {
  final String txHash;
  final String amount;
  final String fee;

  const SendResult({
    required this.txHash,
    required this.amount,
    required this.fee,
  });

  Map<String, dynamic> toJson() => {
        'tx_hash': txHash,
        'amount': amount,
        'fee': fee,
      };
}
