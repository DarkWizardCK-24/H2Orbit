import 'dart:io';

import 'package:flutter/services.dart';

/// `flutter test` draws every glyph as a wide box unless fonts are loaded,
/// which makes layouts overflow that are fine on a device. Load the real
/// Poppins weights and the Material icon font so tests (and screenshots) match.
Future<void> loadAppFonts() async {
  ByteData bytes(String path) =>
      ByteData.sublistView(File(path).readAsBytesSync());

  final poppins = FontLoader('Poppins');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    poppins.addFont(Future.value(bytes('assets/fonts/Poppins-$weight.ttf')));
  }
  await poppins.load();

  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? 'C:/src/flutter';
  final icons = FontLoader('MaterialIcons')
    ..addFont(
      Future.value(
        bytes(
          '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
        ),
      ),
    );
  await icons.load();
}
