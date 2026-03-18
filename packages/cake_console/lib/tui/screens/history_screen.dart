import 'package:dart_lipgloss/dart_lipgloss.dart';
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
  Map<String, String>? _txDetail;

  HistoryScreen(this._bus);

  @override
  String get title => 'History';

  @override
  List<String> get supportedCommands => const ['history.list', 'history.details'];

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

    // Clamp selection after list changes
    if (_txs.isNotEmpty) {
      _selectedIndex = _selectedIndex.clamp(0, _txs.length - 1);
    } else {
      _selectedIndex = 0;
    }

    // Viewport: show only what fits
    final availableHeight = (height - 6).clamp(1, _txs.length);
    _scrollOffset = _scrollOffset.clamp(0, (_txs.length - 1).clamp(0, _txs.length));
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

    final parts = <String>[header, '', ...rows];
    if (scrollInfo.isNotEmpty) parts.add(scrollInfo);

    // Show transaction details if selected
    if (_txDetail != null) {
      parts.add('');
      parts.add(successStyle().render('  Transaction Details:'));
      for (final entry in _txDetail!.entries) {
        parts.add(mutedStyle().render('  ${entry.key}: ${entry.value}'));
      }
    }

    parts.add('');
    parts.add(mutedStyle().render('  Enter: details  Up/Down: navigate  Esc: close details'));

    return joinVertical(posLeft, parts);
  }

  @override
  void handleInput(TerminalEvent event) {
    if (event.key == TerminalKey.escape) {
      _txDetail = null;
      return;
    }
    if (_txs.isEmpty) return;
    final maxIndex = _txs.length - 1;
    if (event.key == TerminalKey.up) {
      _selectedIndex = (_selectedIndex - 1).clamp(0, maxIndex);
      _txDetail = null;
    } else if (event.key == TerminalKey.down) {
      _selectedIndex = (_selectedIndex + 1).clamp(0, maxIndex);
      _txDetail = null;
    } else if (event.key == TerminalKey.enter) {
      _showDetails();
    }
  }

  void _showDetails() {
    if (_txs.isEmpty) return;
    final tx = _txs[_selectedIndex];
    _bus.dispatch('history.details', {'id': tx.id}).then((result) {
      if (result.success && result.data != null) {
        try {
          final json = (result.data as dynamic).toJson();
          if (json is Map) {
            _txDetail = json.map((k, v) => MapEntry(k.toString(), v.toString()));
          }
        } catch (_) {
          _txDetail = {'id': tx.id, 'amount': tx.amount, 'date': tx.dateFormatted};
        }
      }
      onStateChanged?.call();
    });
  }
}
