import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart'
    show ImageRenderMethodForWeb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart';

void main() {
  testWidgets('Issue 496: forwards httpHeaders to CachedNetworkImage', (
    tester,
  ) async {
    const headers = {'Authorization': 'Bearer abc'};
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 100,
          height: 100,
          child: CredentialedNetworkImage(
            imageUrl: 'https://example.test/img.png',
            httpHeaders: headers,
          ),
        ),
      ),
    );

    final widget = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(widget.httpHeaders, headers);
    expect(widget.imageUrl, 'https://example.test/img.png');
  });

  testWidgets(
    'Issue 757: uses the HttpGet web renderer so the auth header is sent on '
    'web (the default <img> renderer cannot)',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 100,
            height: 100,
            child: CredentialedNetworkImage(
              imageUrl: 'https://example.test/id.webp',
              httpHeaders: {'Authorization': 'Bearer abc'},
            ),
          ),
        ),
      );

      // CachedNetworkImage forwards the render method onto the
      // CachedNetworkImageProvider it builds (exposed via the OctoImage in its
      // subtree), not as a field on the widget itself.
      final octo = tester.widget(
        find.byWidgetPredicate((w) => w.runtimeType.toString() == 'OctoImage'),
      );
      final provider = (octo as dynamic).image as CachedNetworkImageProvider;
      expect(provider.imageRenderMethodForWeb, ImageRenderMethodForWeb.HttpGet);
    },
  );

  testWidgets('Issue 496: renders errorBuilder when image fails to load', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 100,
          height: 100,
          child: CredentialedNetworkImage(
            imageUrl: 'https://invalid.test/missing.png',
            httpHeaders: const {},
            errorBuilder: (_) => const Text('failed'),
          ),
        ),
      ),
    );

    // CachedNetworkImage exposes the errorBuilder via its errorWidget
    // builder; confirm we wired it through.
    final widget = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(widget.errorWidget, isNotNull);
  });
}
