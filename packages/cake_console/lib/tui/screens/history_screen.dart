import 'package:dart_lipgloss/dart_lipgloss.dart';
import 'package:dart_lipgloss/table.dart' as lip_table;
import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_headless/dto/transaction_summary.dart';
import 'package:cake_console/tui/tui_theme.dart';
import 'package:cake_console/tui/terminal_driver.dart';
import 'package:cake_console/tui/screen.dart';

class HistoryScreen extends TuiScreen {
  final CommandBus _bus;
  List<TransactionSummary> _txs = [];
  int _selectedIndex = 0;
  int _scrollOffset = 0;
  bool _isLoading = true;

  HistoryScreen(this._bus);

  @override
  String get title => 'History';

  @override
  Future<void> init() async => refresh();

  @override
  Future<void> refresh() async {
    try {
      final result = await _bus.dispatch('history.list', {'limit': 50});
      _txs = result.success
          ? (result.data as List<TransactionSummary>?) ?? []
          : [];
    } catch (_) {
      _txs = [];
    }
    _isLoading = false;
  }

  @override
  String render(int width, int height, CommandBus bus) {
    if (_isLoading) return mutedStyle().render('  Loading...');

    final header = panelStyle().width(width - 4).render('Transaction History');

    if (_txs.isEmpty) {
      return joinVertical(posLeft, [
        header,
        '',
        mutedStyle().render('  No transactions'),
      ]);
    }

    // Viewport: show only what fits
    final availableHeight = (height - 6).clamp(1, _txs.length);
    if (_selectedIndex < _scrollOffset) {
      _scrollOffset = _selectedIndex;
    }
    if (_selectedIndex >= _scrollOffset + availableHeight) {
      _scrollOffset = _selectedIndex - availableHeight + 1;
    }

    final visible = _txs.skip(_scrollOffset).take(availableHeight).toList();

    final rows = visible.asMap().entries.map((e) {
      final globalIdx = e.key + _scrollOffset;
      final isSelected = globalIdx == _selectedIndex;
      final tx = e.value;
      final marker = isSelected ? '> ' : '  ';
      final dir = tx.isIncoming ? 'IN ' : 'OUT';
      final status = tx.isPending ? 'Pending' : 'Confirmed';
      final style =
          isSelected ? Style().bold(true).foreground(cakeText) : mutedStyle();
      return style.render(
          '$marker${tx.dateFormatted}  $dir  ${tx.amount}  ${tx.confirmations}  $status');
    }).toList();

    final scrollInfo = _txs.length > availableHeight
        ? mutedStyle().render(
            '  Showing ${_scrollOffset + 1}-${_scrollOffset + visible.length} of ${_txs.length}')
        : '';

    return joinVertical(
        posLeft, [header, '', ...rows, if (scrollInfo.isNotEmpty) scrollInfo]);
  }

  @override
  void handleInput(TerminalEvent event) {
    if (_txs.isEmpty) return;
    final maxIndex = _txs.length - 1;
    if (event.key == TerminalKey.up) {
      _selectedIndex = (_selectedIndex - 1).clamp(0, maxIndex);
    } else if (event.key == TerminalKey.down) {
      _selectedIndex = (_selectedIndex + 1).clamp(0, maxIndex);
    }
  }
}
