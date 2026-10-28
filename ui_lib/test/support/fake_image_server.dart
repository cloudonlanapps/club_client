import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';

/// The bearer value [FakeImageServer] serves authed images to.
const fakeImageGoodToken = {'Authorization': 'Bearer good'};

/// A 1x1 PNG.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwAD'
  'hgGAWjR9awAAAABJRU5ErkJggg==',
);

var _managerCount = 0;

/// The HTTP layer under `CachedNetworkImage` in a widget test (#409).
///
/// Serves a PNG to [fakeImageGoodToken], or to anyone for a URL with
/// `/public/` in it; refuses everything else with 401. Records the
/// Authorization of every request in [requests]. While [hold] is set,
/// responses wait for it.
///
/// [install] puts it behind a fresh in-memory `CachedNetworkImage` cache
/// manager and clears the image cache.
class FakeImageServer extends FileService {
  final List<String?> requests = [];
  Completer<void>? hold;

  void install() {
    CachedNetworkImageProvider.defaultCacheManager = CacheManager(
      Config(
        'fake-image-server-${_managerCount++}',
        repo: NonStoringObjectProvider(),
        fileSystem: MemoryCacheSystem(),
        fileService: this,
      ),
    );
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
  }

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final auth = headers?['Authorization'];
    requests.add(auth);
    await hold?.future;
    final ok =
        url.contains('/public/') || auth == fakeImageGoodToken['Authorization'];
    return _Response(ok ? 200 : 401, ok ? _png : const []);
  }
}

class _Response implements FileServiceResponse {
  _Response(this.statusCode, this.bytes);

  @override
  final int statusCode;
  final List<int> bytes;

  @override
  Stream<List<int>> get content => Stream.value(bytes);

  @override
  int? get contentLength => bytes.length;

  @override
  DateTime get validTill => DateTime.now().add(const Duration(days: 1));

  @override
  String? get eTag => null;

  @override
  String get fileExtension => '.png';
}

/// Lets the fetches and the decodes finish, and then the cache store's
/// 10-second cleanup timer, which would otherwise outlive the test.
Future<void> settleImages(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pump(const Duration(seconds: 11));
}

/// How many decoded images are on screen.
int imagesShown(WidgetTester tester) => tester
    .widgetList<RawImage>(find.byType(RawImage))
    .where((raw) => raw.image != null)
    .length;
