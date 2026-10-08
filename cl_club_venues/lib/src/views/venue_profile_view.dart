import 'package:cl_club_forms/cl_club_forms.dart'
    show LocationEditForm, LocationEditFormState, TwoColumnGrid;
import 'package:cl_member_auth/cl_member_auth.dart'
    show authStateProvider, imageAuthHeadersProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        clVenueDetailProvider,
        clVenuesMasterProvider,
        imagePickerProvider,
        venueImageProvider,
        venueMediaMutationProvider;
import 'package:cl_server_config/cl_server_config.dart' show DateTimeFormat;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show
        ActionButton,
        CredentialedNetworkImage,
        EditableMarkdown,
        EditableSectionCard,
        ImageUploadAffordance,
        LoadingView,
        MapEmbed,
        ThemedMarkdown,
        TitleRow,
        pickAndConfirmImage;

import '../models/venue_form_helpers.dart' show VenueFormSubmit;
import '../widgets/venue_rename_dialog.dart';

/// Editable venue profile. Each section is a `ShadCard` with inline edit
/// affordances — description (markdown popover), location (address dialog),
/// flags (live checkboxes), rename/delete (management section).
class VenueProfileView extends ConsumerWidget {
  const VenueProfileView({
    required this.venueId,
    required this.onDeleted,
    this.onBack,
    this.onHistory,
    super.key,
  });

  final int venueId;
  final VoidCallback onDeleted;
  final VoidCallback? onBack;

  /// Opens the venue's audit history. Supplied by the host; the title-row
  /// affordance is shown only to admins (issue #207).
  final VoidCallback? onHistory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(clVenueDetailProvider(venueId));
    // Editing is admin-only. Affordances are hidden / disabled otherwise.
    final canEdit = ref.watch(authStateProvider).valueOrNull?.isAdmin ?? false;
    return detail.when(
      loading: () => const LoadingView(),
      error: (e, _) => Center(child: Text('Could not load venue: $e')),
      data: (venue) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitleRow(
              title: venue.name,
              onBack: onBack,
              onHistory: canEdit ? onHistory : null,
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    VenueOverviewCard(venue: venue, canEdit: canEdit),
                    const SizedBox(height: 20),
                    VenueLocationCard(venue: venue, canEdit: canEdit),
                    const SizedBox(height: 20),
                    VenueFlagsCard(venue: venue, canEdit: canEdit),
                    if (canEdit) ...[
                      const SizedBox(height: 20),
                      VenueManagementSection(
                        venue: venue,
                        onDeleted: onDeleted,
                      ),
                    ],
                    const SizedBox(height: 20),
                    VenueInfoCard(venue: venue),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Hero card: image on the left/top, name + description on the right/bottom.
/// The description is edited inline via [EditableMarkdown]; no separate edit
/// route. Falls back to an icon when no image URL is set.
class VenueOverviewCard extends ConsumerWidget {
  const VenueOverviewCard({
    required this.venue,
    required this.canEdit,
    super.key,
  });

  final Venue venue;
  final bool canEdit;

  Future<void> _saveDescription(
    BuildContext context,
    WidgetRef ref,
    String updated,
  ) async {
    final value = updated.trim();
    try {
      await ref
          .read(clVenuesMasterProvider.notifier)
          .updateVenue(
            venue.id,
            description: () => value.isEmpty ? null : value,
          );
    } on Object catch (_) {
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('Could not update description. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 700;
    final description = venue.description ?? '';

    final image = VenueHeroImage(venueId: venue.id, canEdit: canEdit);
    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(venue.name, style: theme.textTheme.h4),
          const SizedBox(height: 12),
          if (canEdit)
            EditableMarkdown(
              data: description,
              label: 'Description',
              emptyText: 'No description provided.',
              onSave: (updated) => _saveDescription(context, ref, updated),
            )
          else if (description.isNotEmpty)
            ThemedMarkdown(data: description, textAlign: TextAlign.justify)
          else
            Text('No description provided.', style: theme.textTheme.muted),
        ],
      ),
    );

    if (isMobile) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: double.infinity, height: 220, child: image),
            content,
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 240),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 280, child: image),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}

/// Renders the venue image from the v2 media link table (`venue_image` tag)
/// via [venueImageProvider] and [CredentialedNetworkImage], falling back to a
/// centered `mapPin` icon on a muted background when no image is set or it
/// fails to load. Admins see the [VenueImageUploadAffordance] overlaid
/// top-right to replace / remove it.
class VenueHeroImage extends ConsumerWidget {
  const VenueHeroImage({
    required this.venueId,
    required this.canEdit,
    super.key,
  });

  final int venueId;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final placeholder = ColoredBox(
      color: theme.colorScheme.muted,
      child: Center(
        child: Icon(
          LucideIcons.mapPin,
          size: 56,
          color: theme.colorScheme.mutedForeground,
        ),
      ),
    );
    final url = ref.watch(venueImageProvider(venueId)).valueOrNull;
    final headers = ref.watch(imageAuthHeadersProvider).valueOrNull ?? const {};
    return Stack(
      fit: StackFit.expand,
      children: [
        if (url == null)
          placeholder
        else
          ColoredBox(
            color: theme.colorScheme.muted,
            child: CredentialedNetworkImage(
              imageUrl: url,
              httpHeaders: headers,
              fit: BoxFit.cover,
              errorBuilder: (_) => placeholder,
            ),
          ),
        if (canEdit)
          Positioned(
            top: 12,
            right: 12,
            child: VenueImageUploadAffordance(venueId: venueId),
          ),
      ],
    );
  }
}

/// Connected affordance wrapping the shared [ImageUploadAffordance]: wires the
/// venue media provider, owns the pick→confirm→upload call and its error
/// toast. The re-entrancy guard and disable/spinner split live in the shared
/// widget.
class VenueImageUploadAffordance extends ConsumerWidget {
  const VenueImageUploadAffordance({required this.venueId, super.key});

  final int venueId;

  Future<void> _replace(BuildContext context, WidgetRef ref) async {
    final picked = await pickAndConfirmImage(
      context,
      picker: ref.read(imagePickerProvider),
    );
    if (picked == null || !context.mounted) return;
    try {
      await ref
          .read(venueMediaMutationProvider(venueId).notifier)
          .uploadImage(
            bytes: picked.bytes,
            filename: picked.filename,
            contentType: picked.mimeType,
          );
    } on Object catch (_) {
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('Could not update image. Please try again.'),
        ),
      );
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(venueMediaMutationProvider(venueId).notifier).clearImage();
    } on Object catch (_) {
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('Could not remove image. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploading = ref.watch(venueMediaMutationProvider(venueId)).isLoading;
    final hasImage = ref.watch(venueImageProvider(venueId)).valueOrNull != null;
    return ImageUploadAffordance(
      uploading: uploading,
      onReplace: () => _replace(context, ref),
      onRemove: hasImage ? () => _remove(context, ref) : null,
    );
  }
}

/// Combined Address + Map section, edited in place. Read mode shows the
/// address and the embedded map; the pencil (admins only) flips it into an
/// inline address + map-link form.
class VenueLocationCard extends ConsumerStatefulWidget {
  const VenueLocationCard({
    required this.venue,
    required this.canEdit,
    super.key,
  });

  final Venue venue;
  final bool canEdit;

  @override
  ConsumerState<VenueLocationCard> createState() => VenueLocationCardState();
}

class VenueLocationCardState extends ConsumerState<VenueLocationCard> {
  final _formKey = GlobalKey<LocationEditFormState>();

  Future<bool> _save(Map<String, dynamic> values) async {
    try {
      await VenueFormSubmit.updateLocation(
        venueId: widget.venue.id,
        values: values,
        notifier: ref.read(clVenuesMasterProvider.notifier),
      );
      if (!mounted) return true;
      ShadToaster.of(context).show(
        const ShadToast(description: Text('Location updated.')),
      );
      return true;
    } on Object catch (_) {
      if (!mounted) return false;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('Could not update location. Please try again.'),
        ),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final venue = widget.venue;
    final address = venue.address;
    final mapUri = venue.mapUri;
    final hasAddress = address != null && address.trim().isNotEmpty;
    final hasMap = mapUri != null && mapUri.trim().isNotEmpty;
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    return EditableSectionCard<Map<String, dynamic>>(
      title: 'Location',
      leadingIcon: LucideIcons.map,
      canEdit: widget.canEdit,
      editMaxWidth: 460,
      read: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasAddress)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.mapPin,
                  size: 16,
                  color: theme.colorScheme.mutedForeground,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(address, style: theme.textTheme.p)),
              ],
            )
          else
            Text('No address on file.', style: theme.textTheme.muted),
          const SizedBox(height: 16),
          if (hasMap)
            MapEmbed(mapUri: mapUri, height: isMobile ? 240 : 320)
          else
            Text('No map link provided.', style: theme.textTheme.muted),
        ],
      ),
      editBuilder: ({required enabled}) => LocationEditForm(
        key: _formKey,
        initialAddress: venue.address ?? '',
        initialMapUri: venue.mapUri ?? '',
        enabled: enabled,
      ),
      onValidate: () => _formKey.currentState?.validate(),
      isDirty: () => _formKey.currentState?.isDirty ?? false,
      onSave: _save,
    );
  }
}

/// Boolean flags. With permission, toggling a checkbox immediately persists
/// the change via `updateVenue` (disabled while a save is in flight to prevent
/// double-toggling). Without permission the checkboxes are disabled and just
/// display the current values.
class VenueFlagsCard extends ConsumerStatefulWidget {
  const VenueFlagsCard({required this.venue, required this.canEdit, super.key});

  final Venue venue;
  final bool canEdit;

  @override
  ConsumerState<VenueFlagsCard> createState() => VenueFlagsCardState();
}

class VenueFlagsCardState extends ConsumerState<VenueFlagsCard> {
  bool isSaving = false;

  Future<void> handleToggle({bool? isDefault, bool? isFeatured}) async {
    setState(() => isSaving = true);
    try {
      await ref
          .read(clVenuesMasterProvider.notifier)
          .updateVenue(
            widget.venue.id,
            isDefault: isDefault,
            isFeatured: isFeatured,
          );
    } on Object catch (_) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('Could not update venue. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final venue = widget.venue;
    final enabled = widget.canEdit && !isSaving;
    return ShadCard(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShadCheckbox(
            value: venue.isDefault,
            enabled: enabled,
            onChanged: (v) => handleToggle(isDefault: v),
            label: const Text('This is the default venue'),
          ),
          const SizedBox(height: 12),
          ShadCheckbox(
            value: venue.isFeatured,
            enabled: enabled,
            onChanged: (v) => handleToggle(isFeatured: v),
            label: const Text('This venue is featured'),
          ),
        ],
      ),
    );
  }
}

/// Audit info — mirrors `AccountInfoSection` and `ClEventAuditInfo`.
class VenueInfoCard extends StatelessWidget {
  const VenueInfoCard({required this.venue, super.key});

  final Venue venue;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Venue Info', style: theme.textTheme.h4),
          const SizedBox(height: 12),
          VenueAuditField(
            label: 'Created',
            value: venue.createdAtUtc.toLocalDateTimeMedium(),
          ),
          const SizedBox(height: 8),
          VenueAuditField(
            label: 'Last updated',
            value: venue.updatedAtUtc.toLocalDateTimeMedium(),
          ),
        ],
      ),
    );
  }
}

class VenueAuditField extends StatelessWidget {
  const VenueAuditField({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.small),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.muted,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(value, style: theme.textTheme.p),
        ),
      ],
    );
  }
}

/// Grid of admin actions: Rename + Delete. Placeholders fill the remaining
/// slots so the 2×2 grid keeps its shape (mirrors `UserManagementSection`).
class VenueManagementSection extends ConsumerStatefulWidget {
  const VenueManagementSection({
    required this.venue,
    required this.onDeleted,
    super.key,
  });

  final Venue venue;
  final VoidCallback onDeleted;

  @override
  ConsumerState<VenueManagementSection> createState() =>
      VenueManagementSectionState();
}

class VenueManagementSectionState
    extends ConsumerState<VenueManagementSection> {
  bool isBusy = false;

  /// Shown on the name field of the rename dialog when the save is refused.
  static const String renameFailedMessage =
      'Could not rename venue. Please try again.';

  /// Renames the venue through the rename dialog, which stays open until the
  /// name is saved; a refusal shows on its field.
  Future<void> handleRename() async {
    final toaster = ShadToaster.of(context);
    final newName = await showVenueRenameDialog(
      context,
      widget.venue.name,
      onSave: writeName,
    );
    if (newName == null) return;
    toaster.show(const ShadToast(description: Text('Venue renamed.')));
  }

  /// Writes [name]; `null` once saved, else the refusal, said for people.
  Future<String?> writeName(String name) async {
    try {
      await ref
          .read(clVenuesMasterProvider.notifier)
          .updateVenue(widget.venue.id, name: name);
      return null;
    } on Object catch (_) {
      return renameFailedMessage;
    }
  }

  Future<void> handleDelete() async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => PointerInterceptor(
        child: ShadDialog(
          title: const Text('Delete venue?'),
          description: const Text(
            'This will soft-delete the venue. It can be restored later.',
          ),
          actions: [
            ShadButton.outline(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ShadButton.destructive(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => isBusy = true);
    try {
      await ref
          .read(clVenuesMasterProvider.notifier)
          .deleteVenue(widget.venue.id);
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast(description: Text('Deleted "${widget.venue.name}".')),
      );
      widget.onDeleted();
    } on Object catch (_) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('Could not delete venue. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final buttons = <Widget>[
      ActionButton(
        label: 'Rename',
        onPressed: isBusy ? null : handleRename,
      ),
      ActionButton(
        label: 'Delete',
        onPressed: isBusy ? null : handleDelete,
      ),
    ];
    while (buttons.length < 4) {
      buttons.add(
        const IgnorePointer(
          child: Opacity(
            opacity: 0,
            child: ActionButton(label: ''),
          ),
        ),
      );
    }

    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Venue Management', style: theme.textTheme.h4),
          const SizedBox(height: 12),
          TwoColumnGrid(
            spacing: 8,
            runSpacing: 8,
            singleColumnBreakpoint: 0,
            children: buttons,
          ),
        ],
      ),
    );
  }
}
