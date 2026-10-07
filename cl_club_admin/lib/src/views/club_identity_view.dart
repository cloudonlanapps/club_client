import 'package:cl_remote_store/cl_remote_store.dart'
    show clClubIdentityMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart' show LoadingView, TitleRow;

import '../models/club_identity_form_helpers.dart';
import '../widgets/club_address_card.dart';
import '../widgets/club_contact_card.dart';
import '../widgets/club_details_card.dart';
import '../widgets/club_translations_card.dart';

/// The club's identity (club_core#20): name, short name, inquiry email and
/// the public contact block — the `club_info` preference the website and
/// the server's email branding and inquiry routing read.
///
/// Three sections — Club, Contact, Address — each a card that shows its
/// values and edits them in place, saved on its own. Translatable fields
/// take a default and a text for each language offered: the languages the
/// stored values already use, plus those added in the Translations card
/// during this visit. Adding a language stores nothing; a translation is
/// saved with its section. Gating is the screen's job; this view asserts
/// the super-admin precondition.
class ClubIdentityView extends ConsumerStatefulWidget {
  const ClubIdentityView({required this.currentUser, this.onBack, super.key});

  /// Key of the scrolling list of section cards, for tests and the
  /// integration suite.
  static const Key listKey = ValueKey('clubIdentity.list');

  /// Space around the section cards.
  static const EdgeInsets listPadding = EdgeInsets.fromLTRB(24, 8, 24, 24);

  /// Gap between two section cards.
  static const double cardGap = 16;

  /// The viewer; a super-admin.
  final UserPrivate currentUser;

  /// Leaves the screen; null shows no back affordance.
  final VoidCallback? onBack;

  @override
  ConsumerState<ClubIdentityView> createState() => ClubIdentityViewState();
}

/// State of [ClubIdentityView]: the languages added in this visit.
class ClubIdentityViewState extends ConsumerState<ClubIdentityView> {
  /// The language codes added in the Translations card, in the order they
  /// were added. Not stored until a section saves a translation in one.
  final List<String> addedLanguages = [];

  /// Offers [language] on every translatable field.
  void addLanguage(String language) {
    if (addedLanguages.contains(language)) return;
    setState(() => addedLanguages.add(language));
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
            // A single scroll child, so no input is ever disposed
            // off-screen.
            data: (identity) {
              final stored = clubIdentityLanguagesOf(identity);
              final languages = [
                ...stored,
                ...addedLanguages.where((l) => !stored.contains(l)),
              ];
              return SingleChildScrollView(
                key: ClubIdentityView.listKey,
                padding: ClubIdentityView.listPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: ClubIdentityView.cardGap,
                  children: [
                    ClubDetailsCard(identity: identity, languages: languages),
                    ClubContactCard(identity: identity, languages: languages),
                    ClubAddressCard(identity: identity, languages: languages),
                    ClubTranslationsCard(
                      languages: languages,
                      onAdd: addLanguage,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
