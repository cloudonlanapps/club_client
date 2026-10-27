import 'package:cl_club_app/src/utils/pdf_actions.dart';
import 'package:cl_club_app/src/utils/share_outcome.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;
import 'package:ui_lib/ui_lib.dart' show PdfAction;

final Uint8List _pdf = Uint8List.fromList([37, 80, 68, 70]);

void main() {
  group('Issue 324: the PDF action of each platform', () {
    PdfActionKind kind({
      required bool web,
      required TargetPlatform platform,
      bool canShareFiles = false,
    }) => pdfActionKindFor(
      web: web,
      platform: platform,
      canShareFiles: canShareFiles,
    );

    test('Issue 324: the app on Android or iOS shares', () {
      for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
        expect(kind(web: false, platform: platform), PdfActionKind.share);
      }
    });

    test('Issue 324: a phone’s browser that can share files shares', () {
      for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
        expect(
          kind(web: true, platform: platform, canShareFiles: true),
          PdfActionKind.share,
        );
      }
    });

    test('Issue 324: a phone’s browser that cannot share files downloads', () {
      for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
        expect(kind(web: true, platform: platform), PdfActionKind.download);
      }
    });

    test('Issue 324: a desktop browser downloads, even one that can share '
        'files', () {
      for (final platform in [
        TargetPlatform.linux,
        TargetPlatform.macOS,
        TargetPlatform.windows,
      ]) {
        for (final canShareFiles in [false, true]) {
          expect(
            kind(web: true, platform: platform, canShareFiles: canShareFiles),
            PdfActionKind.download,
          );
        }
      }
    });

    test('Issue 324: the desktop app opens the PDF viewer, as before', () {
      for (final platform in [
        TargetPlatform.linux,
        TargetPlatform.macOS,
        TargetPlatform.windows,
      ]) {
        expect(kind(web: false, platform: platform), PdfActionKind.open);
      }
    });
  });

  group('Issue 324: share, falling back to download', () {
    Future<List<String>> run(ShareOutcome outcome) async {
      final calls = <String>[];
      await shareOrDownload(
        _pdf,
        'Membership form.pdf',
        share: (bytes, fileName) async {
          calls.add('share $fileName');
          return outcome;
        },
        download: (bytes, fileName) async => calls.add('download $fileName'),
      );
      return calls;
    }

    test('Issue 324: a shared file is not downloaded', () async {
      expect(await run(ShareOutcome.shared), ['share Membership form.pdf']);
    });

    test('Issue 324: a share the browser refuses downloads the file '
        'instead', () async {
      expect(await run(ShareOutcome.refused), [
        'share Membership form.pdf',
        'download Membership form.pdf',
      ]);
    });

    test('Issue 324: a share the person cancels downloads nothing', () async {
      expect(await run(ShareOutcome.cancelled), ['share Membership form.pdf']);
    });
  });

  group('Issue 324: each action’s button and work', () {
    late List<String> calls;

    Future<void> runKind(PdfActionKind kind, {ShareOutcome? outcome}) async {
      calls = [];
      final action = pdfActionOf(
        kind,
        share: (bytes, fileName) async {
          calls.add('share $fileName');
          return outcome ?? ShareOutcome.shared;
        },
        download: (bytes, fileName) async => calls.add('download $fileName'),
        open: (bytes, fileName) async => calls.add('open $fileName'),
      );
      await action.run(_pdf, 'Trial.pdf');
    }

    test('Issue 324: Share shows a share icon and shares', () async {
      final action = pdfActionOf(
        PdfActionKind.share,
        share: (_, _) async => ShareOutcome.shared,
        download: (_, _) async {},
        open: (_, _) async {},
      );
      expect(action.label, PdfActionStrings.share);
      expect(action.icon, LucideIcons.share2);
      await runKind(PdfActionKind.share);
      expect(calls, ['share Trial.pdf']);
    });

    test('Issue 324: Share falls back to download when refused', () async {
      await runKind(PdfActionKind.share, outcome: ShareOutcome.refused);
      expect(calls, ['share Trial.pdf', 'download Trial.pdf']);
    });

    test('Issue 324: Download shows a download icon and downloads', () async {
      final action = pdfActionOf(
        PdfActionKind.download,
        share: (_, _) async => ShareOutcome.shared,
        download: (_, _) async {},
        open: (_, _) async {},
      );
      expect(action.label, PdfActionStrings.download);
      expect(action.icon, LucideIcons.download);
      await runKind(PdfActionKind.download);
      expect(calls, ['download Trial.pdf']);
    });

    test('Issue 324: the desktop app’s button stays Download and opens the '
        'viewer', () async {
      final action = pdfActionOf(
        PdfActionKind.open,
        share: (_, _) async => ShareOutcome.shared,
        download: (_, _) async {},
        open: (_, _) async {},
      );
      expect(action.label, PdfActionStrings.download);
      expect(action.icon, LucideIcons.download);
      await runKind(PdfActionKind.open);
      expect(calls, ['open Trial.pdf']);
    });
  });

  group('Issue 341: the test stand-in for the platform', () {
    tearDown(() => debugPdfBytesHandler = null);

    PdfAction action(List<String> calls) => withDebugPdfBytesHandler(
      pdfActionOf(
        PdfActionKind.open,
        share: (_, _) async => ShareOutcome.shared,
        download: (_, _) async {},
        open: (bytes, fileName) async => calls.add('open $fileName'),
      ),
    );

    test('Issue 341: without a stand-in the platform’s action runs', () async {
      final calls = <String>[];
      final wrapped = action(calls);
      expect(wrapped.label, PdfActionStrings.download);
      expect(wrapped.icon, LucideIcons.download);
      await wrapped.run(_pdf, 'Trial.pdf');
      expect(calls, ['open Trial.pdf']);
    });

    test(
      'Issue 341: a stand-in takes the bytes in place of the platform',
      () async {
        final calls = <String>[];
        final taken = <Uint8List>[];
        debugPdfBytesHandler = (bytes, fileName) async {
          taken.add(bytes);
          calls.add('stand-in $fileName');
        };
        await action(calls).run(_pdf, 'Trial.pdf');
        expect(calls, ['stand-in Trial.pdf']);
        expect(taken.single, _pdf);
      },
    );
  });
}
