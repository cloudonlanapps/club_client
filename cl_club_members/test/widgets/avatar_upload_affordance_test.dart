import 'dart:async';

import 'package:cl_club_members/src/widgets/avatar_upload_affordance.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

class _RecordingAvatarMutationNotifier extends AvatarMutationNotifier {
  _RecordingAvatarMutationNotifier({this.throwOnUpload = false});

  /// When true, [upload] throws after recording the call so the affordance's
  /// failure path (destructive toast) can be exercised.
  final bool throwOnUpload;

  List<Map<String, Object?>> calls = [];

  @override
  Future<void> build(String username) async {}

  @override
  Future<void> upload({
    required List<int> bytes,
    required String filename,
    required String contentType,
    required bool allowOthersToSee,
  }) async {
    calls.add({
      'bytes': bytes.length,
      'filename': filename,
      'contentType': contentType,
      'allowOthersToSee': allowOthersToSee,
    });
    if (throwOnUpload) throw Exception('server rejected the upload');
  }
}

// 1x1 transparent PNG to satisfy Image.memory in the preview.
const _pixelPngBytes = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];

Future<PickedImage?> _stubPicker() async => const PickedImage(
  bytes: _pixelPngBytes,
  filename: 'avatar.png',
  mimeType: 'image/png',
);

void main() {
  testWidgets(
    'Issue 556: Cancel closes the preview dialog without calling upload',
    (tester) async {
      final notifier = _RecordingAvatarMutationNotifier();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            avatarMutationProvider.overrideWith(() => notifier),
          ],
          child: const ShadApp(
            home: Scaffold(
              body: Center(
                child: AvatarUploadAffordance(
                  username: 'alice',
                  picker: _stubPicker,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.byTooltip('Change photo'));
      await tester.pumpAndSettle();

      expect(find.text('Update profile photo'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Update profile photo'), findsNothing);
      expect(notifier.calls, isEmpty);
    },
  );

  testWidgets(
    'Issue 556: OK with checkbox unchecked uploads with allowOthersToSee=false',
    (tester) async {
      final notifier = _RecordingAvatarMutationNotifier();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            avatarMutationProvider.overrideWith(() => notifier),
          ],
          child: const ShadApp(
            home: Scaffold(
              body: Center(
                child: AvatarUploadAffordance(
                  username: 'alice',
                  picker: _stubPicker,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.byTooltip('Change photo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(notifier.calls, hasLength(1));
      final call = notifier.calls.single;
      expect(call['filename'], 'avatar.png');
      expect(call['contentType'], 'image/png');
      expect(call['allowOthersToSee'], false);
      expect(call['bytes'], _pixelPngBytes.length);
    },
  );

  testWidgets(
    'Issue 556: ticking the checkbox uploads with allowOthersToSee=true',
    (tester) async {
      final notifier = _RecordingAvatarMutationNotifier();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            avatarMutationProvider.overrideWith(() => notifier),
          ],
          child: const ShadApp(
            home: Scaffold(
              body: Center(
                child: AvatarUploadAffordance(
                  username: 'alice',
                  picker: _stubPicker,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.byTooltip('Change photo'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ShadCheckbox));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(notifier.calls, hasLength(1));
      expect(notifier.calls.single['allowOthersToSee'], true);
    },
  );

  testWidgets(
    'Issue 556: cancelled picker (no image) shows no dialog and no upload',
    (tester) async {
      final notifier = _RecordingAvatarMutationNotifier();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            avatarMutationProvider.overrideWith(() => notifier),
          ],
          child: ShadApp(
            home: Scaffold(
              body: Center(
                child: AvatarUploadAffordance(
                  username: 'alice',
                  picker: () async => null,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.byTooltip('Change photo'));
      await tester.pumpAndSettle();

      expect(find.text('Update profile photo'), findsNothing);
      expect(notifier.calls, isEmpty);
    },
  );

  testWidgets(
    'Issue 565: dialog pre-ticks checkbox when current avatar is public',
    (tester) async {
      final notifier = _RecordingAvatarMutationNotifier();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            avatarMutationProvider.overrideWith(() => notifier),
            avatarVisibilityProvider('alice').overrideWith((_) async => true),
          ],
          child: const ShadApp(
            home: Scaffold(
              body: Center(
                child: AvatarUploadAffordance(
                  username: 'alice',
                  picker: _stubPicker,
                ),
              ),
            ),
          ),
        ),
      );

      // Let visibility provider resolve before the user taps the pencil.
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Change photo'));
      await tester.pumpAndSettle();

      // OK without touching the checkbox: should upload as public,
      // honouring the previous setting.
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(notifier.calls, hasLength(1));
      expect(notifier.calls.single['allowOthersToSee'], true);
    },
  );

  testWidgets(
    'Issue 693: second tap while the picker is open does not open a second '
    'picker',
    (tester) async {
      final notifier = _RecordingAvatarMutationNotifier();
      var pickerCalls = 0;
      final gate = Completer<PickedImage?>();
      Future<PickedImage?> blockingPicker() {
        pickerCalls++;
        return gate.future;
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            avatarMutationProvider.overrideWith(() => notifier),
            avatarVisibilityProvider('alice').overrideWith((_) async => false),
          ],
          child: ShadApp(
            home: Scaffold(
              body: Center(
                child: AvatarUploadAffordance(
                  username: 'alice',
                  picker: blockingPicker,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      // First tap starts the (still-pending) picker.
      await tester.tap(find.byTooltip('Change photo'));
      await tester.pump();
      expect(pickerCalls, 1);

      // Second tap while the picker is open must be a no-op.
      await tester.tap(find.byTooltip('Change photo'));
      await tester.pump();
      expect(pickerCalls, 1);

      // Release the picker; the single in-flight flow proceeds normally.
      gate.complete(
        const PickedImage(
          bytes: _pixelPngBytes,
          filename: 'avatar.png',
          mimeType: 'image/png',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(pickerCalls, 1);
      expect(notifier.calls, hasLength(1));
    },
  );

  testWidgets(
    'Issue 565: dialog leaves checkbox unticked when current avatar is '
    'restricted',
    (tester) async {
      final notifier = _RecordingAvatarMutationNotifier();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            avatarMutationProvider.overrideWith(() => notifier),
            avatarVisibilityProvider('alice').overrideWith((_) async => false),
          ],
          child: const ShadApp(
            home: Scaffold(
              body: Center(
                child: AvatarUploadAffordance(
                  username: 'alice',
                  picker: _stubPicker,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Change photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(notifier.calls, hasLength(1));
      expect(notifier.calls.single['allowOthersToSee'], false);
    },
  );

  testWidgets(
    'Issue 709: a throwing picker surfaces a toast and does not upload',
    (tester) async {
      final notifier = _RecordingAvatarMutationNotifier();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            avatarMutationProvider.overrideWith(() => notifier),
          ],
          child: ShadApp(
            home: Scaffold(
              body: Center(
                child: AvatarUploadAffordance(
                  username: 'alice',
                  picker: () async => throw Exception('dialog crashed'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.byTooltip('Change photo'));
      await tester.pumpAndSettle();

      // The failure is visible (no silent return) and no preview/upload runs.
      expect(find.textContaining("Couldn't open the image picker"), findsOne);
      expect(find.text('Update profile photo'), findsNothing);
      expect(notifier.calls, isEmpty);
    },
  );

  testWidgets(
    'Issue 710: a failed upload surfaces a destructive toast after the '
    'preview is confirmed',
    (tester) async {
      final notifier = _RecordingAvatarMutationNotifier(throwOnUpload: true);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            avatarMutationProvider.overrideWith(() => notifier),
          ],
          child: const ShadApp(
            home: Scaffold(
              body: Center(
                child: AvatarUploadAffordance(
                  username: 'alice',
                  picker: _stubPicker,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.byTooltip('Change photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // The upload was attempted and its failure surfaced to the user.
      expect(notifier.calls, hasLength(1));
      // Issue 138: in fixed text; an upload that may have landed says so.
      expect(find.text(uncertainWriteMessage), findsOne);
      expect(find.textContaining('server rejected the upload'), findsNothing);
    },
  );
}
