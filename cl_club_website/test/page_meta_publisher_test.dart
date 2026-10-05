import 'package:cl_club_website/cl_club_website.dart';
import 'package:cl_club_website/src/models/contact_map_config.dart';
import 'package:cl_club_website/src/models/page_meta.dart';
import 'package:cl_club_website/src/providers/page_meta.dart';
import 'package:cl_club_website/src/widgets/page_meta_publisher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const config = SiteConfig(
  fullName: 'Example Club',
  shortName: 'EXC',
  apiBaseUrl: 'http://localhost:8000/v1',
  map: ContactMapConfig(mapUri: ''),
);

void main() {
  late ProviderContainer container;
  final written = <String?>[];

  setUp(() {
    written.clear();
    container = ProviderContainer(
      overrides: [
        siteConfigProvider.overrideWithValue(config),
        pageDescriptionWriterProvider.overrideWithValue(written.add),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: child),
    ),
  );

  testWidgets('Issue 29: a page publishes its title and description', (
    tester,
  ) async {
    await pump(
      tester,
      const PageMetaPublisher(
        pageName: 'Our Coaches',
        description: 'Meet our **expert** team',
        child: SizedBox.shrink(),
      ),
    );
    await tester.pump();
    expect(
      container.read(pageMetaProvider),
      const PageMeta(
        title: 'Our Coaches | Example Club',
        description: 'Meet our expert team',
      ),
    );
  });

  testWidgets('Issue 29: the home page is titled with the club name', (
    tester,
  ) async {
    await pump(tester, const PageMetaPublisher(child: SizedBox.shrink()));
    await tester.pump();
    expect(
      container.read(pageMetaProvider),
      const PageMeta(title: 'Example Club'),
    );
  });

  testWidgets('Issue 29: a page republishes when its data arrives', (
    tester,
  ) async {
    await pump(
      tester,
      const PageMetaPublisher(pageName: 'Camp', child: SizedBox.shrink()),
    );
    await tester.pump();
    await pump(
      tester,
      const PageMetaPublisher(
        pageName: 'Winter Camp',
        description: 'Five days on ice',
        child: SizedBox.shrink(),
      ),
    );
    await tester.pump();
    expect(
      container.read(pageMetaProvider),
      const PageMeta(
        title: 'Winter Camp | Example Club',
        description: 'Five days on ice',
      ),
    );
  });

  testWidgets('Issue 29: the page on top wins, and the one under it returns', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: navigator,
          home: const PageMetaPublisher(
            pageName: 'Our Venues',
            child: SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pump();
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const PageMetaPublisher(
          pageName: 'North Rink',
          child: SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      container.read(pageMetaProvider)!.title,
      'North Rink | Example Club',
    );
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(
      container.read(pageMetaProvider)!.title,
      'Our Venues | Example Club',
    );
  });
}
