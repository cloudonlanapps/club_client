import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'target.dart';
import 'web_files.dart';

/// Entries of the template's `android/` not copied: build output, tool
/// state and machine-local files, which Flutter's build makes again.
const androidSkipped = {
  '.gradle',
  '.cxx',
  'build',
  'local.properties',
  'gradlew',
  'gradlew.bat',
  'gradle-wrapper.jar',
  'GeneratedPluginRegistrant.java',
  'key.properties',
};

/// Whether [name], an entry of the template's `android/`, is copied.
bool copiesAndroidEntry(String name) =>
    !androidSkipped.contains(name) &&
    !name.endsWith('.iml') &&
    !name.endsWith('.keystore') &&
    !name.endsWith('.jks');

final _androidId = RegExp(r'^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$');

/// [id] as given, or a [GeneratorException] when it is not an Android
/// application id (two or more dot-separated names, each starting with a
/// letter).
String checkAndroidId(String id) {
  if (!_androidId.hasMatch(id)) {
    throw GeneratorException(
      '--android-id must look like org.example.club, got "$id"',
    );
  }
  return id;
}

/// The app module's `build.gradle.kts` with its application id set to [id].
/// The namespace (the Kotlin package of `MainActivity`) stays the template's.
String withApplicationId(String gradle, String id) {
  final line = RegExp('applicationId = "[^"]*"');
  if (line.allMatches(gradle).length != 1) {
    throw const GeneratorException(
      'android/app/build.gradle.kts must set applicationId exactly once',
    );
  }
  return gradle.replaceFirst(line, 'applicationId = "$id"');
}

/// The main `AndroidManifest.xml` with the app's [name] as its label, and,
/// when [cleartext], plain-HTTP traffic allowed (an `http://` API).
String withAndroidLabel(
  String manifest,
  String name, {
  required bool cleartext,
}) {
  final label = RegExp('android:label="[^"]*"');
  if (label.allMatches(manifest).length != 1) {
    throw const GeneratorException(
      'android/app/src/main/AndroidManifest.xml must set android:label once',
    );
  }
  final attributes = [
    'android:label="${_xmlAttribute(name)}"',
    if (cleartext) 'android:usesCleartextTraffic="true"',
  ].join('\n        ');
  return manifest.replaceFirst(label, attributes);
}

String _xmlAttribute(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('"', '&quot;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

/// The launcher icons, made from the brand's `icon_1024.png`, keyed by their
/// path under `android/`.
Map<String, Uint8List> renderAndroidIcons(Uint8List source) {
  final image = decodeBrandIcon(source);
  return {
    for (final MapEntry(key: density, value: size) in const {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    }.entries)
      'app/src/main/res/mipmap-$density/ic_launcher.png': img.encodePng(
        img.copyResize(
          image,
          width: size,
          height: size,
          interpolation: img.Interpolation.average,
        ),
      ),
  };
}
