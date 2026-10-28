import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart';

import '../support/fake_image_server.dart';

const Map<String, String> _good = fakeImageGoodToken;
const _stale = {'Authorization': 'Bearer stale'};
const _authedUrl = 'https://example.test/media/doc.png';
const _publicUrl = 'https://example.test/public/logo.png';

void main() {
  late FakeImageServer server;

  // The default cache manager is never read: building it needs
  // path_provider.
  setUp(() => server = FakeImageServer()..install());

  Future<void> pumpImage(
    WidgetTester tester,
    Map<String, String> headers, {
    String url = _authedUrl,
    bool requiresAuth = false,
  }) => tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 100,
        height: 100,
        child: CredentialedNetworkImage(
          imageUrl: url,
          httpHeaders: headers,
          requiresAuth: requiresAuth,
          placeholderBuilder: (_) => const Text('loading'),
          errorBuilder: (_) => const Text('failed'),
        ),
      ),
    ),
  );

  testWidgets(
    'Issue 409: a refused fetch without a token is fetched again when the '
    'token arrives, and the image shows',
    (tester) async {
      await pumpImage(tester, const {});
      await settleImages(tester);
      expect(server.requests, [null]);
      expect(find.text('failed'), findsOneWidget);
      expect(imagesShown(tester), 0);

      await pumpImage(tester, _good);
      await settleImages(tester);
      expect(server.requests, [null, 'Bearer good']);
      expect(find.text('failed'), findsNothing);
      expect(imagesShown(tester), 1);
    },
  );

  testWidgets(
    'Issue 409: a fetch in flight with a stale token is tried again with the '
    'new one once it is refused',
    (tester) async {
      server.hold = Completer<void>();
      await pumpImage(tester, _stale);
      await settleImages(tester);
      expect(server.requests, ['Bearer stale']);

      await pumpImage(tester, _good);
      await settleImages(tester);
      server.hold!.complete();
      server.hold = null;
      await settleImages(tester);

      expect(server.requests, ['Bearer stale', 'Bearer good']);
      expect(find.text('failed'), findsNothing);
      expect(imagesShown(tester), 1);
    },
  );

  testWidgets(
    'Issue 409: an unchanged token does not fetch again on rebuild, nor does '
    'a new token once the image has loaded',
    (tester) async {
      await pumpImage(tester, _good);
      await settleImages(tester);
      expect(server.requests, ['Bearer good']);
      expect(imagesShown(tester), 1);

      for (var i = 0; i < 3; i++) {
        await pumpImage(tester, Map.of(_good));
        await settleImages(tester);
      }
      await pumpImage(tester, const {'Authorization': 'Bearer next'});
      await settleImages(tester);

      expect(server.requests, ['Bearer good']);
      expect(imagesShown(tester), 1);
    },
  );

  testWidgets(
    'Issue 409: requiresAuth fetches nothing until a token arrives, then '
    'fetches with it',
    (tester) async {
      await pumpImage(tester, const {}, requiresAuth: true);
      await settleImages(tester);
      expect(server.requests, isEmpty);
      expect(find.text('loading'), findsOneWidget);
      expect(find.text('failed'), findsNothing);

      await pumpImage(tester, _good, requiresAuth: true);
      await settleImages(tester);
      expect(server.requests, ['Bearer good']);
      expect(imagesShown(tester), 1);
    },
  );

  testWidgets('Issue 409: a public image still loads with no headers', (
    tester,
  ) async {
    await pumpImage(tester, const {}, url: _publicUrl);
    await settleImages(tester);
    expect(server.requests, [null]);
    expect(find.text('failed'), findsNothing);
    expect(imagesShown(tester), 1);
  });
}
