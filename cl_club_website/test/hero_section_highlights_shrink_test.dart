import 'package:cl_club_branding/cl_club_branding.dart'
    show initialThemeModeProvider;
import 'package:cl_club_events/cl_club_events.dart'
    show Highlight, HighlightType, publicHighlightsProvider;
import 'package:cl_club_website/cl_club_website.dart';
import 'package:cl_club_website/src/widgets/hero_section.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show clPublicSiteMediaProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class _Highlight implements Highlight {
  const _Highlight(this.title);

  @override
  final String title;

  @override
  String get id => title;

  @override
  HighlightType get type => HighlightType.event;

  @override
  String get subtitle => '';

  @override
  String? get imageUrl => null;

  @override
  String? get stamp => null;

  @override
  bool get isFeatured => false;
}

/// The highlights the server lists right now.
final _listed = StateProvider<List<Highlight>>(
  (ref) => const [_Highlight('One'), _Highlight('Two'), _Highlight('Three')],
);

void main() {
  testWidgets('Issue 197: the landing hero survives its highlights '
      'shrinking under the carousel', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // The bundled hero image is an asset this package's tests do not
    // bundle; its load failing is not what this test is about.
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is UnimplementedError &&
          details.toString().contains('AssetImage')) {
        return;
      }
      original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);
    final container = ProviderContainer(
      overrides: [
        initialThemeModeProvider.overrideWithValue(ThemeMode.light),
        clPublicSiteMediaProvider.overrideWith((ref, slot) => null),
        publicHighlightsProvider.overrideWith(
          (ref) async => ref.watch(_listed),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ShadApp(
          home: SiteStringsScope(
            strings: SiteStrings(const {}),
            child: const Scaffold(body: HeroSection()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    tester.state<HeroSectionState>(find.byType(HeroSection)).goToPage(2);
    await tester.pump();
    expect(find.text('Three'), findsWidgets);

    container.read(_listed.notifier).state = const [_Highlight('One')];
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('One'), findsWidgets);
    // Unmount, so no carousel timer outlives the test.
    await tester.pumpWidget(const SizedBox());
  });
}
