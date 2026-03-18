import 'package:dart_lipgloss/dart_lipgloss.dart';
import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_headless/dto/node_info.dart';
import 'package:cake_console/tui/tui_theme.dart';
import 'package:cake_console/tui/terminal_driver.dart';
import 'package:cake_console/tui/screen.dart';

class NodesScreen extends TuiScreen {
  final CommandBus _bus;
  List<NodeInfo> _nodes = [];
  int _selectedIndex = 0;
  int _scrollOffset = 0;
  bool _isLoading = true;
  String? _statusMessage;
  bool _statusIsError = false;

  NodesScreen(this._bus);

  @override
  String get title => 'Nodes';

  @override
  Future<void> init() async => refresh();

  @override
  Future<void> refresh() async {
    try {
      final result = await _bus.dispatch('nodes.list', {});
      _nodes = result.success
          ? (result.data as List<NodeInfo>?) ?? []
          : [];
    } catch (_) {
      _nodes = [];
    }
    if (_nodes.isNotEmpty) {
      _selectedIndex = _selectedIndex.clamp(0, _nodes.length - 1);
    } else {
      _selectedIndex = 0;
    }
    _isLoading = false;
  }

  @override
  String render(int width, int height, CommandBus bus) {
    if (_isLoading) return mutedStyle().render('  Loading...');

    final header = panelStyle().width(width - 4).render('Nodes');

    if (_nodes.isEmpty) {
      return joinVertical(posLeft, [
        header,
        '',
        mutedStyle().render('  No nodes configured.'),
      ]);
    }

    final availableHeight = (height - 6).clamp(1, _nodes.length);
    if (_selectedIndex < _scrollOffset) _scrollOffset = _selectedIndex;
    if (_selectedIndex >= _scrollOffset + availableHeight) {
      _scrollOffset = _selectedIndex - availableHeight + 1;
    }

    final visible = _nodes.asMap().entries.skip(_scrollOffset).take(availableHeight);

    final rows = visible.map((e) {
      final isSelected = e.key == _selectedIndex;
      final n = e.value;
      final style = isSelected
          ? Style().bold(true).foreground(cakeText)
          : mutedStyle();
      final marker = isSelected ? '> ' : '  ';
      final active = n.isActive ? ' [active]' : '';
      final trusted = n.isTrusted ? ' [trusted]' : '';
      return style.render('$marker${n.name ?? n.uri}$active$trusted');
    }).toList();

    final parts = <String>[header, '', ...rows];
    parts.add('');
    parts.add(mutedStyle().render('  Enter: select  d: delete  Up/Down: navigate'));

    if (_statusMessage != null) {
      final style = _statusIsError ? errorStyle() : successStyle();
      parts.add(style.render('  $_statusMessage'));
    }

    return joinVertical(posLeft, parts);
  }

  @override
  void handleInput(TerminalEvent event) {
    if (_nodes.isEmpty) return;
    final maxIndex = _nodes.length - 1;
    if (event.key == TerminalKey.up) {
      _selectedIndex = (_selectedIndex - 1).clamp(0, maxIndex);
    } else if (event.key == TerminalKey.down) {
      _selectedIndex = (_selectedIndex + 1).clamp(0, maxIndex);
    } else if (event.key == TerminalKey.enter) {
      _selectNode();
    } else if (event.key == TerminalKey.char && event.char == 'd') {
      _deleteNode();
    }
  }

  void _selectNode() {
    if (_nodes.isEmpty) return;
    final n = _nodes[_selectedIndex];
    _statusMessage = 'Selecting ${n.name ?? n.uri}...';
    _statusIsError = false;
    onStateChanged?.call();
    _bus.dispatch('nodes.select', {'uri': n.uri}).then((result) {
      _statusMessage = result.success
          ? 'Selected ${n.name ?? n.uri}'
          : (result.message ?? 'Failed');
      _statusIsError = !result.success;
      refresh().then((_) => onStateChanged?.call());
    });
  }

  void _deleteNode() {
    if (_nodes.isEmpty) return;
    final n = _nodes[_selectedIndex];
    _statusMessage = 'Deleting ${n.name ?? n.uri}...';
    _statusIsError = false;
    onStateChanged?.call();
    _bus.dispatch('nodes.delete', {'uri': n.uri}).then((result) {
      _statusMessage = result.success
          ? 'Deleted ${n.name ?? n.uri}'
          : (result.message ?? 'Failed');
      _statusIsError = !result.success;
      refresh().then((_) => onStateChanged?.call());
    });
  }
}
