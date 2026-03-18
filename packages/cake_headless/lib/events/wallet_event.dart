enum WalletEventType {
  balanceChanged,
  syncStatusChanged,
  transactionReceived,
  transactionSent,
  walletOpened,
  walletClosed,
  nodeChanged,
  torStatusChanged,
  connectionStatusChanged,
}

class WalletEvent {
  final WalletEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int sequence;

  static int _nextSequence = 0;

  WalletEvent(this.type, {this.data = const {}})
      : timestamp = DateTime.now(),
        sequence = _nextSequence++;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sequence': sequence,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  String toString() => 'WalletEvent($type, seq: $sequence, data: $data, at: $timestamp)';
}
