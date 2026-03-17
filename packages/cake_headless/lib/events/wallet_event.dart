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

  WalletEvent(this.type, {this.data = const {}})
      : timestamp = DateTime.now();

  @override
  String toString() => 'WalletEvent($type, data: $data, at: $timestamp)';
}
