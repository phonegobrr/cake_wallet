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
  bool _isLoading = true;

  ReceiveScreen(this._bus);

  @override
  String get title => 'Receive';

  @override
  List<String> get supportedCommands => const ['receive.address', 'receive.uri', 'receive.list'];

  @override
  Future<void> init() async => refresh();

  @override
  Future<void> refresh() async {
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

    final addrText =
        Style().bold(true).foreground(cakeText).render(_address!.address);
    final qr = renderQrCode(_address!.address);

    return joinVertical(posLeft, [
      header,
      '',
      '  Address:',
      '  $addrText',
      '',
      qr,
    ]);
  }

  @override
  void handleInput(TerminalEvent event) {
    // No input handling needed for receive screen
  }
}
