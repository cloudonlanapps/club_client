import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../credentialed_network_image.dart';
import 'identity_document_slot.dart';

/// Full-screen preview for uploaded identity-document images.
///
/// Each slot uses `InteractiveViewer(Image.network(...))` so the user can
/// pinch / drag to zoom in on the ID. No Riverpod, no cl_gallery_viewer —
/// identity documents are always images, never videos or PDFs.
void showIdentityDocumentsPreview({
  required BuildContext context,
  required List<IdentityDocumentSlot> items,
  required String initialItemId,
  Map<String, String> httpHeaders = const {},
}) {
  if (items.isEmpty) return;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => IdentityDocumentsPreviewPage(
        items: items,
        initialItemId: initialItemId,
        httpHeaders: httpHeaders,
      ),
    ),
  );
}

class IdentityDocumentsPreviewPage extends StatefulWidget {
  const IdentityDocumentsPreviewPage({
    required this.items,
    required this.initialItemId,
    required this.httpHeaders,
    super.key,
  });

  final List<IdentityDocumentSlot> items;
  final String initialItemId;
  final Map<String, String> httpHeaders;

  @override
  State<IdentityDocumentsPreviewPage> createState() =>
      IdentityDocumentsPreviewPageState();
}

class IdentityDocumentsPreviewPageState
    extends State<IdentityDocumentsPreviewPage> {
  late final PageController controller;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.items.indexWhere(
      (s) => s.id == widget.initialItemId,
    );
    currentIndex = initialIndex < 0 ? 0 : initialIndex;
    controller = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final total = widget.items.length;
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.items[currentIndex].fileName ?? 'Document',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (total > 1)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${currentIndex + 1} / $total',
                  style: theme.textTheme.small,
                ),
              ),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 768;
          return Stack(
            children: [
              PageView.builder(
                controller: controller,
                itemCount: total,
                onPageChanged: (i) => setState(() => currentIndex = i),
                itemBuilder: (_, i) => ZoomablePage(
                  slot: widget.items[i],
                  httpHeaders: widget.httpHeaders,
                ),
              ),
              if (isDesktop && total > 1) ...[
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: NavButton(
                      icon: Icons.chevron_left,
                      tooltip: 'Previous',
                      onPressed: currentIndex > 0
                          ? () => _goTo(currentIndex - 1)
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: NavButton(
                      icon: Icons.chevron_right,
                      tooltip: 'Next',
                      onPressed: currentIndex < total - 1
                          ? () => _goTo(currentIndex + 1)
                          : null,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _goTo(int index) {
    controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }
}

class NavButton extends StatelessWidget {
  const NavButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final disabled = onPressed == null;
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.background.withValues(
                alpha: disabled ? 0.5 : 0.85,
              ),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 24,
              color: disabled
                  ? theme.colorScheme.mutedForeground
                  : theme.colorScheme.foreground,
            ),
          ),
        ),
      ),
    );
  }
}

/// A single image page that supports pinch-to-zoom while leaving the
/// surrounding [PageView] free to handle horizontal swipes at 1x scale.
///
/// We disable `panEnabled` on [InteractiveViewer] when the transform is the
/// identity matrix, so [PageView] receives the swipe gesture. Once the user
/// zooms in, panning is re-enabled inside the image and the swipe boundary
/// only kicks in if the user releases at the page edge.
class ZoomablePage extends StatefulWidget {
  const ZoomablePage({
    required this.slot,
    required this.httpHeaders,
    super.key,
  });

  final IdentityDocumentSlot slot;
  final Map<String, String> httpHeaders;

  @override
  State<ZoomablePage> createState() => ZoomablePageState();
}

class ZoomablePageState extends State<ZoomablePage> {
  late final TransformationController transformController;
  bool isZoomed = false;

  @override
  void initState() {
    super.initState();
    transformController = TransformationController();
    transformController.addListener(_onTransformChanged);
  }

  void _onTransformChanged() {
    final zoomed = transformController.value != Matrix4.identity();
    if (zoomed != isZoomed) {
      setState(() => isZoomed = zoomed);
    }
  }

  @override
  void dispose() {
    transformController
      ..removeListener(_onTransformChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: transformController,
      panEnabled: isZoomed,
      minScale: 1,
      maxScale: 4,
      child: Center(
        child: CredentialedNetworkImage(
          imageUrl: widget.slot.uri,
          httpHeaders: widget.httpHeaders,
          fit: BoxFit.contain,
          errorBuilder: (_) => ImageLoadError(filename: widget.slot.fileName),
        ),
      ),
    );
  }
}

class ImageLoadError extends StatelessWidget {
  const ImageLoadError({this.filename, super.key});

  final String? filename;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image_outlined, size: 48),
          const SizedBox(height: 8),
          Text(filename ?? 'Image', style: theme.textTheme.muted),
        ],
      ),
    );
  }
}
