import 'dart:typed_data';

import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

/// `/media` download, recording each call and serving fixed bytes;
/// [failWith] makes it throw.
class _FakeMediaDownload extends Fake implements MediaSource {
  _FakeMediaDownload({this.failWith});

  final Exception? failWith;
  final List<String> calls = [];

  @override
  Future<List<int>> download(
    String uuid, {
    String variant = 'original',
    String? filename,
  }) async {
    calls.add('$uuid $variant $filename');
    if (failWith case final e?) throw e;
    return const [37, 80, 68, 70];
  }
}

ProviderContainer _container(_FakeMediaDownload media) {
  final container = ProviderContainer(
    overrides: [
      secureClientProvider.overrideWith(
        (ref) async => fakeSecureClient(media: media),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

const MediaRef _copy = MediaRef(
  uuid: 'copy-uuid',
  mimeType: 'application/pdf',
  filename: 'review.pdf',
);

void main() {
  group('Issue 173: clMediaBytesReaderProvider', () {
    test(
      'Issue 173: downloads the original through the signed-in client',
      () async {
        final media = _FakeMediaDownload();
        final read = _container(media).read(clMediaBytesReaderProvider);

        final bytes = await read(_copy);

        expect(bytes, isA<Uint8List>());
        expect(bytes, [37, 80, 68, 70]);
        expect(media.calls, ['copy-uuid original review.pdf']);
      },
    );

    test('Issue 173: a refused download is rethrown unchanged', () async {
      const refused = ServerException(
        statusCode: 403,
        code: 'FORBIDDEN',
        message: 'Forbidden',
      );
      final read = _container(
        _FakeMediaDownload(failWith: refused),
      ).read(clMediaBytesReaderProvider);

      await expectLater(read(_copy), throwsA(same(refused)));
    });
  });
}
