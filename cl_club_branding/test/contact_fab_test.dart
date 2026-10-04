import 'package:cl_club_branding/cl_club_branding.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show ContactInfo, contactInfoProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show LocalizedText;
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:simple_speed_dial/simple_speed_dial.dart';
import 'package:url_launcher_platform_interface/link.dart' show LinkDelegate;
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// Records what a tap would open instead of opening it.
class _RecordingUrlLauncher extends UrlLauncherPlatform {
  final List<String> launched = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return true;
  }
}

/// Serves the default English resources for any locale, so a test can run
/// the widget under a language Flutter ships no localizations for.
class _AnyLocale<T> extends LocalizationsDelegate<T> {
  const _AnyLocale(this.value);

  final T value;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<T> load(Locale locale) => SynchronousFuture(value);

  @override
  bool shouldReload(_AnyLocale<T> old) => false;
}

const _contact = ContactInfo(
  clubName: 'Test Club',
  phoneNumber: '+911234567890',
  email: 'club@example.test',
  whatsappMessage: LocalizedText('Hello', {'mr': 'नमस्कार'}),
  emailSubject: LocalizedText('Enquiry', {'mr': 'चौकशी'}),
);

Future<_RecordingUrlLauncher> _pumpFab(
  WidgetTester tester, {
  required Locale locale,
}) async {
  final original = UrlLauncherPlatform.instance;
  final launcher = _RecordingUrlLauncher();
  UrlLauncherPlatform.instance = launcher;
  addTearDown(() => UrlLauncherPlatform.instance = original);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [contactInfoProvider.overrideWithValue(_contact)],
      child: ShadApp(
        home: Scaffold(
          floatingActionButton: Localizations(
            locale: locale,
            delegates: const [
              _AnyLocale<WidgetsLocalizations>(DefaultWidgetsLocalizations()),
              _AnyLocale<MaterialLocalizations>(
                DefaultMaterialLocalizations(),
              ),
            ],
            child: const ContactFab(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return launcher;
}

/// Presses the dial's [label] action, as a tap on it would.
Future<void> _press(WidgetTester tester, String label) async {
  final child = tester
      .widget<SpeedDial>(find.byType(SpeedDial))
      .speedDialChildren
      .singleWhere((c) => c.label == label);
  (child.onPressed as void Function())();
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 53: ContactFab', () {
    testWidgets('Issue 53: renders the dial with heroes disabled', (
      tester,
    ) async {
      await _pumpFab(tester, locale: const Locale('en'));

      expect(find.byType(SpeedDial), findsOneWidget);
      final heroMode = tester.widget<HeroMode>(
        find
            .ancestor(
              of: find.byType(SpeedDial),
              matching: find.byType(HeroMode),
            )
            .first,
      );
      expect(heroMode.enabled, isFalse);
    });

    testWidgets('Issue 53: links resolve in the current language', (
      tester,
    ) async {
      final launcher = await _pumpFab(tester, locale: const Locale('mr'));

      await _press(tester, 'WhatsApp');
      await _press(tester, 'Email');
      await _press(tester, 'Call Us');

      expect(launcher.launched, [
        _contact.whatsappUrl('mr'),
        _contact.emailUrl('mr'),
        _contact.phoneUrl,
      ]);
      expect(launcher.launched.first, contains(Uri.encodeComponent('नमस्कार')));
    });
  });
}
