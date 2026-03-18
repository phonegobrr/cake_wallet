import 'package:dart_lipgloss/dart_lipgloss.dart';
import 'package:cake_console/tui/tui_theme.dart';

/// Reusable TUI modal/dialog rendering helpers.
/// These produce styled strings; callers embed them in their render output.

/// Renders a confirm dialog (Yes/No).
/// [selected] is 0 for Yes, 1 for No.
String renderConfirmDialog(String message, {int selected = 1}) {
  final yesStyle = selected == 0
      ? Style().bold(true).foreground(cakeText).background(cakePrimary).paddingLeft(1).paddingRight(1)
      : mutedStyle().paddingLeft(1).paddingRight(1);
  final noStyle = selected == 1
      ? Style().bold(true).foreground(cakeText).background(cakePrimary).paddingLeft(1).paddingRight(1)
      : mutedStyle().paddingLeft(1).paddingRight(1);

  final dialog = panelStyle().render(
    joinVertical(posCenter, [
      message,
      '',
      joinHorizontal(posCenter, [
        yesStyle.render('Yes'),
        '  ',
        noStyle.render('No'),
      ]),
    ]),
  );
  return dialog;
}

/// Renders a text input dialog.
/// [obscure] hides the input text (for passwords).
String renderTextInputDialog(String label, String value, {bool obscure = false}) {
  final displayValue = obscure ? '*' * value.length : value;
  return panelStyle().render(
    joinVertical(posLeft, [
      Style().bold(true).foreground(cakeText).render(label),
      '',
      '  > $displayValue',
      '',
      mutedStyle().render('Enter: confirm  Esc: cancel'),
    ]),
  );
}

/// Renders a selector dialog (pick from list).
/// [selected] is the currently highlighted index.
String renderSelectorDialog(String title, List<String> options, int selected) {
  final rows = options.asMap().entries.map((e) {
    final isSelected = e.key == selected;
    final style = isSelected
        ? Style().bold(true).foreground(cakeText)
        : mutedStyle();
    final marker = isSelected ? '> ' : '  ';
    return style.render('$marker${e.value}');
  }).toList();

  return panelStyle().render(
    joinVertical(posLeft, [
      Style().bold(true).foreground(cakeText).render(title),
      '',
      ...rows,
      '',
      mutedStyle().render('Up/Down: navigate  Enter: select  Esc: cancel'),
    ]),
  );
}

/// Renders a status toast message.
String renderToast(String message, {bool isError = false}) {
  final style = isError ? errorStyle() : successStyle();
  return style.render('  $message');
}
