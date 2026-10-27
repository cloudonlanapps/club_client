import 'package:cl_remote_store/cl_remote_store.dart'
    show
        clApplicationsMasterProvider,
        currentUserProvider,
        extendedProfileProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show PdfAction;

import '../constants/application_view_sizes.dart';
import '../constants/application_view_strings.dart';
import '../models/application_download.dart';
import '../utils/application_download_refusal.dart';
import '../utils/blank_profile_fields.dart';
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
    if (downloading) return;
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

  /// Fetches the PDF and hands it to the action.
  Future<void> run() async {
    if (downloading) return;
    setState(() {
      downloading = true;
      refusal = null;
    });
    try {
      final notifier = ref.read(clApplicationsMasterProvider.notifier);
      final bytes = await widget.download.fetch(notifier);
      if (mounted) await widget.pdfAction.run(bytes, widget.fileName);
    } on Object catch (e) {
      if (!mounted) return;
      final message = applicationDownloadRefusal(e);
      if (message != null) {
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final refused = refusal;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: ApplicationViewSizes.smallGap,
      children: [
        ShadButton.outline(
          size: ShadButtonSize.sm,
          enabled: !downloading,
          onPressed: onPressed,
          leading: downloading
              ? const SizedBox.square(
                  dimension: ApplicationViewSizes.spinner,
                  child: ShadProgress(),
                )
              : Icon(widget.pdfAction.icon),
          child: Text(widget.label ?? widget.pdfAction.label),
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
