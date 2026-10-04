import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Visual tone for [ErrorView].
///
/// - [destructive]: red icon — true failure (fetch errors, exceptions).
/// - [neutral]: muted icon — non-failure placeholder (access denied,
///   "nothing to show").
enum ErrorTone { destructive, neutral }

/// Unified empty / access-denied / error placeholder.
///
/// Renders a centered column: icon (48 px, tone-coloured) → [title] →
/// optional [subtitle] → optional **Show error code** toggle (when
/// [errorCode] is non-null) → action row (Home / Back / Retry).
///
/// [onHome] is required because every screen that can render an error
/// state must offer a way back to the dashboard; the router is the only
/// component that knows the home route.
class ErrorView extends StatefulWidget {
  const ErrorView({
    required this.title,
    required this.onHome,
    this.subtitle,
    this.errorCode,
    this.icon = LucideIcons.triangleAlert,
    this.tone = ErrorTone.destructive,
    this.onBack,
    this.onRetry,
    super.key,
  });

  /// Main heading (rendered as `theme.textTheme.h4`).
  final String title;

  /// Required navigation back to the app home / dashboard.
  final VoidCallback onHome;

  /// Optional supporting copy (rendered as `theme.textTheme.muted`).
  final String? subtitle;

  /// Raw error string from a catch block. When non-null, a "Show error
  /// code" toggle is rendered; tapping it reveals a selectable
  /// monospaced block so users can copy/paste the diagnostic.
  final String? errorCode;

  /// Icon shown above [title]; defaults to a warning triangle.
  final IconData icon;

  /// Visual tone — `destructive` for failures, `neutral` for
  /// access-denied / empty placeholders.
  final ErrorTone tone;

  /// Optional "Back" action — usually `() => Navigator.pop(context)`.
  final VoidCallback? onBack;

  /// Optional "Retry" action — typically re-invokes the failed fetch.
  final VoidCallback? onRetry;

  @override
  State<ErrorView> createState() => ErrorViewState();
}

class ErrorViewState extends State<ErrorView> {
  bool _showErrorCode = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final toneColor = switch (widget.tone) {
      ErrorTone.destructive => theme.colorScheme.destructive,
      ErrorTone.neutral => theme.colorScheme.mutedForeground,
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 48, color: toneColor),
            const SizedBox(height: 12),
            Text(
              widget.title,
              style: theme.textTheme.h4,
              textAlign: TextAlign.center,
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.subtitle!,
                style: theme.textTheme.muted,
                textAlign: TextAlign.center,
              ),
            ],
            if (widget.errorCode != null) ...[
              const SizedBox(height: 8),
              ShadButton.ghost(
                size: ShadButtonSize.sm,
                onPressed: () => setState(() {
                  _showErrorCode = !_showErrorCode;
                }),
                child: Text(
                  _showErrorCode ? 'Hide error code' : 'Show error code',
                ),
              ),
              if (_showErrorCode) ...[
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.muted,
                    border: Border.all(color: theme.colorScheme.border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SelectableText(
                    widget.errorCode!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                ShadButton(
                  onPressed: widget.onHome,
                  child: const Text('Home'),
                ),
                if (widget.onBack != null)
                  ShadButton.outline(
                    onPressed: widget.onBack,
                    child: const Text('Back'),
                  ),
                if (widget.onRetry != null)
                  ShadButton.outline(
                    onPressed: widget.onRetry,
                    child: const Text('Retry'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
