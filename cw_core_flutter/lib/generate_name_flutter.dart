import 'package:cw_core/generate_name.dart';
import 'package:flutter/services.dart';

/// Call this early in Flutter app startup to configure the asset loader
/// to use rootBundle for loading text assets.
void initFlutterAssetLoader() {
  setAssetLoader((path) => rootBundle.loadString(path));
}
