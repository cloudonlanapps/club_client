import 'package:cl_remote_store/cl_remote_store.dart'
    show
        clApplicationsMasterProvider,
        currentUserProvider,
        extendedProfileProvider;
import 'package:club_sdk_2/club_sdk_2.dart'
    show ApplicationCategoryRequiredException, UserPrivate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show PdfAction;

import '../constants/application_view_sizes.dart';
import '../constants/application_view_strings.dart';
import '../models/application_download.dart';
import '../utils/application_download_refusal.dart';
import '../utils/blank_profile_fields.dart';
import 'application_category_dialog.dart';
import 'profile_complete_dialog.dart';

/// Fetches one application PDF — a member's form or an admin's preview
/// ([download]) — and hands its bytes to [pdfAction] as [fileName]: the
/// app's share, download or viewer, whichever works on the platform
/// (club_client#324). The button shows the action's icon and, unless
/// [label] names it otherwise, its label.
///
/// A member's own form prints from their profile, so before it is fetched
/// the button asks "Is your profile complete?" and lists the printed
/// fields blank on the signed-in member's profile ([blankProfileFields],
/// club_client#340): **Yes** downloads; **No** calls [onOpenProfile], or
/// only closes the dialog when that is null (the button is on the member's
/// profile page already). With nothing blank it downloads without asking.
/// A member's form fetched by an admin, and an admin's preview, are not the
/// viewer's own form and download without asking.
///
/// A member who fits more than one of the template's age categories is
/// then asked which one the form ticks ([showApplicationCategoryDialog],
/// club_client#337), and the form downloads with it; **Cancel** downloads
/// nothing. The server says when that is: the download without a category
/// is refused with the categories the member fits
/// (`ApplicationCategoryRequiredException`), on the member's own form and
/// on an admin's download of a member's form alike. With one fit it
/// downloads without asking. The choice is not remembered. The preview is
/// the server's demo member and never asks.
///
/// Given a [reason], the button is greyed out with it beside it: the
/// download the state forbids (a draft's blank form, club_client#393).
///
/// While it downloads the button is off and shows a spinner. A refusal
/// about the member or the application (not eligible, no identity
/// document, no longer published) shows as a clear message under the
/// button; any other failure is a toast with a fixed message.
class ApplicationDownloadButton extends ConsumerStatefulWidget {
  const ApplicationDownloadButton({
    required this.download,
    required this.pdfAction,
    required this.fileName,
    this.label,
    this.onOpenProfile,
    this.reason,
    this.today,
    super.key,
  });

  /// The PDF to fetch.
  final ApplicationDownload download;

  /// What the fetched PDF is handed to.
  final PdfAction pdfAction;

  /// The name the PDF is shared or saved under.
  final String fileName;

  /// The button's text; the action's label when null.
  final String? label;

  /// Opens the member's profile page when they answer **No** to "Is your
  /// profile complete?"; null only closes the dialog.
  final VoidCallback? onOpenProfile;

  /// Why the download is not allowed now, shown beside the greyed-out
  /// button; null when it is.
  final String? reason;

  /// Today's date for the guardian's age check; the clock's when null.
  final DateTime Function()? today;

  /// Whether the button may ask "Is your profile complete?" first: for the
  /// signed-in member's own form only.
  bool get asksProfileComplete => download is ApplicationOwnForm;

  @override
  ConsumerState<ApplicationDownloadButton> createState() =>
      ApplicationDownloadButtonState();
}

/// State of [ApplicationDownloadButton]: the download in flight and the
/// last refusal.
class ApplicationDownloadButtonState
    extends ConsumerState<ApplicationDownloadButton> {
  /// Whether a download is in flight.
  bool downloading = false;

  /// What the server refused, shown under the button; null for nothing.
  String? refusal;

  /// Asks "Is your profile complete?" when the form is the member's own,
  /// then fetches the PDF and hands it to the action on **Yes**.
  Future<void> onPressed() async {
    if (downloading || widget.reason != null) return;
    if (widget.asksProfileComplete) {
      final blank = blankFields();
      if (blank != null && blank.isEmpty) return run();
      final complete = await showProfileCompleteDialog(context, blank: blank);
      if (!mounted) return;
      if (complete == false) widget.onOpenProfile?.call();
      if (complete != true) return;
    }
    await run();
  }

  /// The printed fields blank on the signed-in member's profile, or null
  /// when the profile is not at hand.
  List<String>? blankFields() {
    final user = ref.read(currentUserProvider);
    if (user is! UserPrivate) return null;
    return blankProfileFields(
      user,
      extendedProfile: ref.read(extendedProfileProvider) == true,
      today: (widget.today ?? DateTime.now)(),
    );
  }

  /// Fetches the PDF, ticking age category [category] when given, and
  /// hands it to the action. Refused because the member fits several
  /// categories and none was given, it asks which one and fetches again
  /// with it.
  Future<void> run({int? category}) async {
    if (downloading) return;
    setState(() {
      downloading = true;
      refusal = null;
    });
    List<int>? fitting;
    try {
      final notifier = ref.read(clApplicationsMasterProvider.notifier);
      final bytes = await widget.download.fetch(notifier, category: category);
      if (mounted) await widget.pdfAction.run(bytes, widget.fileName);
    } on Object catch (e) {
      if (!mounted) return;
      final message = applicationDownloadRefusal(e);
      if (e is ApplicationCategoryRequiredException &&
          category == null &&
          e.categories.length > 1) {
        fitting = e.categories;
      } else if (message != null) {
        setState(() => refusal = message);
      } else {
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            description: Text(ApplicationViewStrings.downloadFailed),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => downloading = false);
    }
    if (fitting == null || !mounted) return;
    final chosen = await showApplicationCategoryDialog(
      context,
      choices: categoryChoices(fitting),
    );
    if (chosen != null && mounted) await run(category: chosen);
  }

  /// The age categories at [indexes] of the template, each by its English
  /// name, or its first name in another language, or else its number.
  List<ApplicationCategoryChoice> categoryChoices(List<int> indexes) {
    final templates = ref.read(clApplicationsMasterProvider).valueOrNull;
    final categories =
        templates?[widget.download.applicationId]?.content.ageCategories ??
        const [];
    String name(int index) {
      if (index >= categories.length) {
        return ApplicationViewStrings.categoryNumber(index);
      }
      final label = categories[index].label;
      return [
        label['en'],
        ...label.values,
      ].whereType<String>().firstWhere(
        (text) => text.trim().isNotEmpty,
        orElse: () => ApplicationViewStrings.categoryNumber(index),
      );
    }

    return [for (final index in indexes) (index: index, name: name(index))];
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final refused = refusal;
    final why = widget.reason;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: ApplicationViewSizes.smallGap,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: ApplicationViewSizes.reasonGap,
          children: [
            ShadButton.outline(
              size: ShadButtonSize.sm,
              enabled: !downloading && why == null,
              onPressed: onPressed,
              leading: downloading
                  ? const SizedBox.square(
                      dimension: ApplicationViewSizes.spinner,
                      child: ShadProgress(),
                    )
                  : Icon(widget.pdfAction.icon),
              child: Text(widget.label ?? widget.pdfAction.label),
            ),
            if (why != null) Text(why, style: theme.textTheme.muted),
          ],
        ),
        if (refused != null)
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: ApplicationViewSizes.refusalWidth,
            ),
            child: Text(
              refused,
              textAlign: TextAlign.end,
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.destructive,
              ),
            ),
          ),
      ],
    );
  }
}
