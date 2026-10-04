import 'package:cl_remote_store/cl_remote_store.dart'
    show SiteMediaSlot, clSiteMediaMasterProvider, imagePickerProvider;
import 'package:club_sdk_2/club_sdk_2.dart'
    show MediaRef, ServerException, UserPrivate;
import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show LoadingView, TitleRow, pickAndConfirmImage;

import '../utils/site_media_refusal.dart';
import '../widgets/media_library_dialog.dart';
import '../widgets/site_media_save_bar.dart';
import '../widgets/site_media_slot_card.dart';

/// The public website's media slots (club_core#19): for each purpose the
/// site defines, what fills it now, and Upload (public on upload), Link
/// existing (public media only) or Clear (back to the site's bundled file).
///
/// Changes collect in a draft; Save writes the whole `site_media` map in one
/// go, and a slot the server refuses as not public says so in place. Gating
/// is the screen's job; this view asserts the super-admin precondition.
class SiteMediaView extends ConsumerStatefulWidget {
  const SiteMediaView({required this.currentUser, this.onBack, super.key});

  final UserPrivate currentUser;
  final VoidCallback? onBack;

  @override
  ConsumerState<SiteMediaView> createState() => SiteMediaViewState();
}

class SiteMediaViewState extends ConsumerState<SiteMediaView> {
  /// Unsaved changes; `null` while the screen shows what is saved.
  Map<String, MediaRef>? draft;

  /// The slot the server refused on the last save.
  String? refusedKey;

  /// A save failure that belongs to no one slot.
  String? formError;

  bool busy = false;

  Map<String, MediaRef> slotsFrom(Map<String, MediaRef> saved) =>
      draft ?? saved;

  void setSlot(Map<String, MediaRef> saved, String key, MediaRef? media) {
    setState(() {
      final next = {...slotsFrom(saved)};
      if (media == null) {
        next.remove(key);
      } else {
        next[key] = media;
      }
      draft = next;
      if (refusedKey == key) refusedKey = null;
      formError = null;
    });
  }

  Future<void> upload(Map<String, MediaRef> saved, SiteMediaSlot slot) async {
    final picked = await pickAndConfirmImage(
      context,
      picker: ref.read(imagePickerProvider),
      title: 'Upload ${slot.label}',
    );
    if (picked == null || !mounted) return;
    final toaster = ShadToaster.of(context);
    setState(() => busy = true);
    try {
      final media = await ref
          .read(clSiteMediaMasterProvider.notifier)
          .uploadPublic(
            bytes: picked.bytes,
            filename: picked.filename,
            contentType: picked.mimeType,
          );
      if (mounted) setSlot(saved, slot.serverKey, media);
    } on Object catch (_) {
      toaster.show(
        const ShadToast.destructive(
          description: Text('Could not upload the file. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> link(Map<String, MediaRef> saved, SiteMediaSlot slot) async {
    final picked = await showMediaLibraryDialog(
      context,
      title: 'Link media to ${slot.label}',
    );
    if (picked != null && mounted) setSlot(saved, slot.serverKey, picked);
  }

  Future<void> save() async {
    final slots = draft;
    if (slots == null) return;
    final toaster = ShadToaster.of(context);
    setState(() => busy = true);
    try {
      await ref.read(clSiteMediaMasterProvider.notifier).save(slots);
      if (!mounted) return;
      setState(() {
        draft = null;
        refusedKey = null;
        formError = null;
      });
      toaster.show(const ShadToast(description: Text('Website media saved.')));
    } on ServerException catch (e) {
      final key = refusedSiteMediaSlot(e, slots);
      if (mounted) {
        setState(() {
          refusedKey = key;
          formError = key == null ? saveFailedMessage : null;
        });
      }
    } on Object catch (_) {
      if (mounted) setState(() => formError = saveFailedMessage);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  /// A save failure the screen cannot pin on a slot.
  static const String saveFailedMessage =
      'Could not save the website media. Please try again.';

  @override
  Widget build(BuildContext context) {
    assert(
      widget.currentUser.isSuperAdmin,
      'SiteMediaView reached by a non-super-admin. Screen gate failed.',
    );
    final saved = ref.watch(clSiteMediaMasterProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitleRow(
          title: 'Website media',
          subtitle: 'Images and video the public website shows',
          onBack: widget.onBack,
        ),
        Expanded(
          child: saved.when(
            loading: () => const LoadingView(message: 'Loading website media…'),
            error: (_, _) => const Center(
              child: Text("Couldn't load the website media."),
            ),
            data: (saved) {
              final slots = slotsFrom(saved);
              return ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  for (final slot in SiteMediaSlot.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SiteMediaSlotCard(
                        serverKey: slot.serverKey,
                        label: slot.label,
                        media: slots[slot.serverKey],
                        busy: busy,
                        error: refusedKey == slot.serverKey
                            ? '${slot.label} is not public: a website '
                                  'visitor could not fetch it. Link public '
                                  'media instead.'
                            : null,
                        onUpload: () => upload(saved, slot),
                        onLink: () => link(saved, slot),
                        onClear: () => setSlot(saved, slot.serverKey, null),
                      ),
                    ),
                  SiteMediaSaveBar(
                    dirty: draft != null && !mapEquals(draft, saved),
                    busy: busy,
                    error: formError,
                    onSave: save,
                    onDiscard: () => setState(() {
                      draft = null;
                      refusedKey = null;
                      formError = null;
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
