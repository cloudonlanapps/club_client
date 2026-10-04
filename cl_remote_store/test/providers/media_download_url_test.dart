import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:cl_server_config/cl_server_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProviderContainer build(String baseUrl) {
    final container = ProviderContainer(
      overrides: [
        serverConfigProvider.overrideWithValue(
          ServerConfig(baseUrl: baseUrl),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('Issue 553: builds v2 media download URL with default variant', () {
    final c = build('https://api.example.com/v1');
    final url = c.read(
      mediaDownloadUrlProvider((uuid: 'abc-123', variant: 'original')),
    );
    expect(
      url,
      'https://api.example.com/v1/media/by_id/abc-123/download?variant=original',
    );
  });

  test('Issue 553: honours explicit variant', () {
    final c = build('https://api.example.com/v1');
    final url = c.read(
      mediaDownloadUrlProvider((uuid: 'u1', variant: 'poster')),
    );
    expect(
      url,
      'https://api.example.com/v1/media/by_id/u1/download?variant=poster',
    );
  });

  test('Issue 553: works without a version prefix on the base URL', () {
    final c = build('https://api.example.com');
    final url = c.read(
      mediaDownloadUrlProvider((uuid: 'u', variant: 'original')),
    );
    expect(
      url,
      'https://api.example.com/media/by_id/u/download?variant=original',
    );
  });
}
