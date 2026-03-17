import 'package:dart_lipgloss/dart_lipgloss.dart';

// Brand colors
final cakePrimary = lipColor('#7D56F4');
final cakeAccent = lipColor('#FF6B6B');
final cakeSuccess = lipColor('#4ECDC4');
final cakeWarning = lipColor('#FFE66D');
final cakeError = lipColor('#FF4444');
final cakeMuted = lipColor('#888899');
final cakeSurface = lipColor('#1A1A2E');
final cakeBorder = lipColor('#333A50');
final cakeText = lipColor('#FAFAFA');
final cakeTextDim = lipColor('#A0A0B0');
final cakeSyncing = lipColor('#FFB84E');

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
