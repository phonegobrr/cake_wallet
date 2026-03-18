import 'package:dart_lipgloss/dart_lipgloss.dart';
import 'package:cake_headless/commands/command_bus.dart';
import 'package:cake_headless/dto/address_entry.dart';
import 'package:cake_console/tui/tui_theme.dart';
import 'package:cake_console/tui/terminal_driver.dart';
import 'package:cake_console/tui/screen.dart';
import 'package:cake_console/tui/widgets/qr_terminal.dart';

class ReceiveScreen extends TuiScreen {
  final CommandBus _bus;
  AddressEntry? _address;
  List<AddressEntry> _addressList = [];
  bool _isLoading = true;
  String? _statusMessage;
  bool _statusIsError = false;
  bool _showList = false;
  int _listSelectedIndex = 0;
  String? _uriDisplay;

  ReceiveScreen(this._bus);

  @override
  String get title => 'Receive';

  @override
  List<String> get supportedCommands =>
      const ['receive.address', 'receive.uri', 'receive.list', 'receive.new', 'receive.rotate'];

  @override
  Future<void> init() async => refresh();

  @override
  Future<void> refresh() async {
    // Clear stale list data on refresh (e.g. after wallet switch)
    _showList = false;
    _addressList = [];
    _listSelectedIndex = 0;
    _uriDisplay = null;
    try {
      final result = await _bus.dispatch('receive.address', {});
      if (result.success) _address = result.data as AddressEntry?;
    } catch (_) {}
    _isLoading = false;
  }

  @override
  String render(int width, int height, CommandBus bus) {
    if (_isLoading) return mutedStyle().render('  Loading...');

    final header = panelStyle().width(width - 4).render('Receive');

    if (_address == null) {
      return joinVertical(posLeft, [
        header,
        '',
        mutedStyle().render('  No wallet open'),
      ]);
    }

    final parts = <String>[header, ''];

    if (_showList && _addressList.isNotEmpty) {
      // Show address list view with scroll support
      parts.add(Style().bold(true).foreground(cakeText).render('  Addresses:'));
      final visibleCount = (height - 10).clamp(1, _addressList.length);
      int scrollStart = 0;
      if (_listSelectedIndex >= visibleCount) {
        scrollStart = _listSelectedIndex - visibleCount + 1;
      }
      for (int i = scrollStart; i < scrollStart + visibleCount && i < _addressList.length; i++) {
        final a = _addressList[i];
        final isSelected = i == _listSelectedIndex;
        final style = isSelected
            ? Style().bold(true).foreground(cakeText)
            : mutedStyle();
        final marker = isSelected ? '> ' : '  ';
        final label = a.label ?? 'Address ${i + 1}';
        parts.add(style.render('$marker$label: ${a.address}'));
      }
      parts.add('');
      parts.add(mutedStyle().render('  Esc: back  Up/Down: navigate'));
    } else {
      // Show primary address + QR
      final addrText =
          Style().bold(true).foreground(cakeText).render(_address!.address);
      final qr = renderQrCode(_address!.address);

      parts.addAll([
        '  Address:',
        '  $addrText',
        '',
        qr,
      ]);

      if (_uriDisplay != null) {
        parts.add('');
        parts.add(successStyle().render('  URI: $_uriDisplay'));
      }

      parts.add('');
      parts.add(mutedStyle().render(
          '  N: new subaddress  R: rotate  L: list addresses  U: show URI'));
    }

    if (_statusMessage != null) {
      final style = _statusIsError ? errorStyle() : successStyle();
      parts.add('');
      parts.add(style.render('  $_statusMessage'));
    }

    return joinVertical(posLeft, parts);
  }

  @override
  void handleInput(TerminalEvent event) {
    if (_showList) {
      if (event.key == TerminalKey.escape) {
        _showList = false;
        _uriDisplay = null;
      } else if (event.key == TerminalKey.up && _addressList.isNotEmpty) {
        _listSelectedIndex =
            (_listSelectedIndex - 1).clamp(0, _addressList.length - 1);
      } else if (event.key == TerminalKey.down && _addressList.isNotEmpty) {
        _listSelectedIndex =
            (_listSelectedIndex + 1).clamp(0, _addressList.length - 1);
      }
      return;
    }

    // Use uppercase letters to avoid conflict with global hotkeys
    // (lowercase n/r/etc. are consumed by the TuiApp hotkey map)
    if (event.key == TerminalKey.char) {
      switch (event.char) {
        case 'N':
          _newSubaddress();
          break;
        case 'R':
          _rotateAddress();
          break;
        case 'L':
          _listAddresses();
          break;
        case 'U':
          _showUri();
          break;
      }
    }
  }

  void _newSubaddress() {
    _statusMessage = 'Generating new subaddress...';
    _statusIsError = false;
    onStateChanged?.call();
    _bus.dispatch('receive.new', {}).then((result) {
      if (result.success) {
        _statusMessage = 'New subaddress generated';
        _statusIsError = false;
        refresh().then((_) => onStateChanged?.call());
      } else {
        _statusMessage = result.message ?? 'Failed';
        _statusIsError = true;
      }
      onStateChanged?.call();
    });
  }

  void _rotateAddress() {
    _statusMessage = 'Rotating address...';
    _statusIsError = false;
    onStateChanged?.call();
    _bus.dispatch('receive.rotate', {}).then((result) {
      if (result.success) {
        _statusMessage = 'Address rotated';
        _statusIsError = false;
        refresh().then((_) => onStateChanged?.call());
      } else {
        _statusMessage = result.message ?? 'Failed';
        _statusIsError = true;
      }
      onStateChanged?.call();
    });
  }

  void _listAddresses() {
    _bus.dispatch('receive.list', {}).then((result) {
      if (result.success && result.data is List) {
        _addressList = (result.data as List).cast<AddressEntry>();
        _showList = true;
        _listSelectedIndex = 0;
      } else {
        _statusMessage = result.message ?? 'Failed to list addresses';
        _statusIsError = true;
      }
      onStateChanged?.call();
    });
  }

  void _showUri() {
    _bus.dispatch('receive.uri', {}).then((result) {
      if (result.success && result.data is Map) {
        final data = result.data as Map;
        _uriDisplay = data['uri']?.toString();
        _statusMessage = null;
      } else {
        _statusMessage = result.message ?? 'Failed to generate URI';
        _statusIsError = true;
      }
      onStateChanged?.call();
    });
  }
}
