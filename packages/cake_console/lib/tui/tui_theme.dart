import 'package:dart_lipgloss/dart_lipgloss.dart';

// Brand colors
final cakePrimary = Color('#7D56F4');
final cakeAccent = Color('#FF6B6B');
final cakeSuccess = Color('#4ECDC4');
final cakeWarning = Color('#FFE66D');
final cakeError = Color('#FF4444');
final cakeMuted = Color('#888899');
final cakeSurface = Color('#1A1A2E');
final cakeBorder = Color('#333A50');
final cakeText = Color('#FAFAFA');
final cakeTextDim = Color('#A0A0B0');
final cakeSyncing = Color('#FFB84E');

Style headerStyle() => Style()
    .bold(true)
    .foreground(cakeText)
    .background(cakePrimary)
    .paddingLeft(1)
    .paddingRight(1);

Style panelStyle() => Style()
    .border(roundedBorder)
    .borderForeground(cakeBorder)
    .padding(1, 2);

Style balanceCardStyle() => Style()
    .border(roundedBorder)
    .borderForeground(cakeSuccess)
    .padding(1, 2);

Style errorStyle() => Style()
    .bold(true)
    .foreground(cakeError);

Style successStyle() => Style()
    .bold(true)
    .foreground(cakeSuccess);

Style mutedStyle() => Style()
    .foreground(cakeMuted);

Style statusStyle(bool synced) => Style()
    .foreground(synced ? cakeSuccess : cakeSyncing);
