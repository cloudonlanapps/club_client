import 'package:cl_remote_store/cl_remote_store.dart'
    show clClubIdentityMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show ClubIdentity, UserPrivate;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show ClubIdentityForm, ClubIdentityFormState, LoadingView, TitleRow;

import '../models/club_identity_form_helpers.dart';
import '../widgets/club_identity_save_bar.dart';

/// The club's identity (club_core#20): name, short name, inquiry email and
/// the public contact block — the `club_info` preference the website and
/// the server's email branding and inquiry routing read.
///
/// One form over the whole document; Save writes it back in one go, over
/// the master's read so keys the form does not edit survive. Translatable
/// fields take a default and optional per-language texts. Gating is the
/// screen's job; this view asserts the super-admin precondition.
class ClubIdentityView extends ConsumerStatefulWidget {
  const ClubIdentityView({required this.currentUser, this.onBack, super.key});

  final UserPrivate currentUser;
  final VoidCallback? onBack;

  @override
  ConsumerState<ClubIdentityView> createState() => ClubIdentityViewState();
}

class ClubIdentityViewState extends ConsumerState<ClubIdentityView> {
  /// Replaced after a save or discard, so the form remounts on the saved
  /// values.
  GlobalKey<ClubIdentityFormState> formKey = GlobalKey();

  bool dirty = false;
  bool busy = false;
  String? saveError;

  /// A save failure, shown above Save.
  static const String saveFailedMessage =
      'Could not save the club details. Please try again.';

  void reset() => setState(() {
    formKey = GlobalKey();
    dirty = false;
    saveError = null;
  });

  Future<void> save(ClubIdentity saved) async {
    final form = formKey.currentState;
    final values = form?.validate();
    if (form == null || values == null) return;
    if (!form.isDirty) return reset();
    final toaster = ShadToaster.of(context);
    setState(() => busy = true);
    try {
      await ClubIdentityFormSubmit.update(
        values: values,
        base: saved,
        notifier: ref.read(clClubIdentityMasterProvider.notifier),
      );
      if (!mounted) return;
      reset();
      toaster.show(const ShadToast(description: Text('Club details saved.')));
    } on Object catch (_) {
      if (mounted) setState(() => saveError = saveFailedMessage);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.currentUser.isSuperAdmin,
      'ClubIdentityView reached by a non-super-admin. Screen gate failed.',
    );
    final saved = ref.watch(clClubIdentityMasterProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitleRow(
          title: 'Club details',
          subtitle: 'Name, contact and address the website and emails show',
          onBack: widget.onBack,
        ),
        Expanded(
          child: saved.when(
            loading: () => const LoadingView(message: 'Loading club details…'),
            error: (_, _) =>
                const Center(child: Text("Couldn't load the club details.")),
            // The form scrolls; Save stays in view below it. A single
            // scroll child, so no input is ever disposed off-screen.
            data: (saved) => Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    key: const ValueKey('clubIdentity.list'),
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: ClubIdentityForm(
                      key: formKey,
                      initialValues: buildClubIdentityFormInitialValues(saved),
                      enabled: !busy,
                      onChanged: () => setState(
                        () => dirty = formKey.currentState?.isDirty ?? false,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: ClubIdentitySaveBar(
                    dirty: dirty,
                    busy: busy,
                    error: saveError,
                    onSave: () => save(saved),
                    onDiscard: reset,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
