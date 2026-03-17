import 'dart:convert';
import 'dart:io';
import 'dart:math';

extension StringExtension on String {
  String capitalized() => "${this[0].toUpperCase()}${this.substring(1)}";
}

/// For Flutter, call setAssetLoader() with a rootBundle-based impl
/// (see cw_core_flutter/lib/generate_name_flutter.dart).
/// For CLI/TUI, uses filesystem reads as fallback.
typedef AssetStringLoader = Future<String> Function(String path);

AssetStringLoader? _assetLoader;

void setAssetLoader(AssetStringLoader loader) => _assetLoader = loader;

Future<String> _loadAsset(String path) async {
  if (_assetLoader != null) return _assetLoader!(path);
  // Fallback: read from filesystem relative to executable
  final file = File(path);
  if (await file.exists()) return file.readAsString();
  // Try relative to script
  final scriptDir = File(Platform.script.toFilePath()).parent.path;
  final altFile = File('$scriptDir/../$path');
  if (await altFile.exists()) return altFile.readAsString();
  throw StateError('Cannot load asset "$path" -- no asset loader configured and file not found');
}

Future<String> generateName() async {
  final randomThing = Random();
  final adjectiveStringRaw = await _loadAsset("assets/text/Wallet_Adjectives.txt");
  final nounStringRaw = await _loadAsset("assets/text/Wallet_Nouns.txt");

  final ls = LineSplitter();
  final adjectives = ls.convert(adjectiveStringRaw);
  final nouns = ls.convert(nounStringRaw);

  final chosenAdjective = adjectives[randomThing.nextInt(adjectives.length)].capitalized();
  final chosenNoun = nouns[randomThing.nextInt(nouns.length)].capitalized();
  return "$chosenAdjective $chosenNoun";
}
