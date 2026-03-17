import 'package:dart_lipgloss/dart_lipgloss.dart';
import 'package:dart_lipgloss/table.dart' as lip_table;
import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_headless/dto/balance_snapshot.dart';
import 'package:cake_headless/dto/transaction_summary.dart';
import 'package:cake_headless/dto/sync_status_summary.dart';
import 'package:cake_console/tui/tui_theme.dart';
import 'package:cake_console/tui/terminal_driver.dart';
import 'package:cake_console/tui/screen.dart';

class DashboardScreen implements TuiScreen {
  final CommandBus _bus;
  BalanceSnapshot? _balance;
  SyncStatusSummary? _syncStatus;
  List<TransactionSummary> _recentTxs = [];
  int _selectedTx = 0;

  DashboardScreen(this._bus) {
    _refresh();
  }

  @override
  String get title => 'Dashboard';

  Future<void> _refresh() async {
    final balResult = await _bus.dispatch('balance.get', {});
    if (balResult.success) _balance = balResult.data as BalanceSnapshot?;

    final syncResult = await _bus.dispatch('sync.status', {});
    if (syncResult.success) _syncStatus = syncResult.data as SyncStatusSummary?;

    final txResult = await _bus.dispatch('history.list', {'limit': 10});
    if (txResult.success) _recentTxs = (txResult.data as List<TransactionSummary>?) ?? [];
  }

  @override
  String render(int width, int height, CommandBus bus) {
    final balText = _balance != null
        ? '${_balance!.available} ${_balance!.currencyTitle}'
        : 'No wallet open';
    final balCard = balanceCardStyle().width(width ~/ 2).render(
        'Available Balance\n$balText');

    final syncText = _syncStatus?.displayText ?? 'No wallet';
    final isSynced = _syncStatus?.isSynced ?? false;
    final syncIndicator = statusStyle(isSynced).render(
        '${isSynced ? "SYNCED" : "SYNCING"} $syncText');

    final topRow = joinHorizontal(posTop, [balCard, '  ', syncIndicator]);

    String txSection;
    if (_recentTxs.isEmpty) {
      txSection = mutedStyle().render('  No transactions yet');
    } else {
      final table = lip_table.Table()
        ..headers(['Date', 'Dir', 'Amount', 'Status'])
        ..rows(_recentTxs.map((tx) => [
              tx.dateFormatted,
              tx.isIncoming ? 'IN ' : 'OUT',
              tx.amount,
              tx.isPending ? 'Pending' : 'Confirmed',
            ]).toList())
        ..borderDef(roundedBorder)
        ..borderColumn(true)
        ..borderStyleDef(Style().foreground(cakePrimary));
      txSection = table.render();
    }

    final actions = mutedStyle().render(
        '[S]end  [R]eceive  [W]allets  [E]xchange  [H]istory');

    return joinVertical(posLeft, [topRow, '', txSection, '', actions]);
  }

  @override
  void handleInput(TerminalEvent event) {
    if (event.key == TerminalKey.up) {
      _selectedTx = (_selectedTx - 1).clamp(0, _recentTxs.length - 1);
    } else if (event.key == TerminalKey.down) {
      _selectedTx = (_selectedTx + 1).clamp(0, _recentTxs.length - 1);
    }
  }
}
