import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'markdown/markdown_composer_field.dart';

/// The values a [BroadcastComposer] hands back when the user taps Send.
///
/// [emailSubject] is non-null only when the user enabled email **and** chose
/// to customize the subject; otherwise the host applies its own default
/// subject. The message [text] doubles as the (markdown) email body.
@immutable
class BroadcastComposeResult {
  const BroadcastComposeResult({
    required this.text,
    required this.sendEmail,
    this.emailSubject,
  });

  final String text;
  final bool sendEmail;
  final String? emailSubject;
}

/// Pure-UI broadcast compose box (no SDK / no Riverpod). Shared by the
/// all-users broadcast panel and the per-group message section.
///
/// Layout matches the legacy single-box composer until the optional email
/// affordances are engaged:
/// - a "Send email" checkbox; when ticked it reveals
/// - a "Customize email subject" checkbox; when ticked it reveals
/// - a subject [ShadInput] above the message box (the email-editor look).
///
/// The composer owns its own controllers, checkbox state and in-flight flag.
/// [onSend] performs the actual send and returns `true` on success, which
/// clears the box; returning `false` (or throwing) leaves the text in place
/// for a retry.
class BroadcastComposer extends StatefulWidget {
  const BroadcastComposer({
    required this.onSend,
    this.placeholder = 'Type a message…',
    this.minLines = 2,
    this.maxLines = 6,
    this.onClose,
    super.key,
  });

  /// Sends the composed message. Returns `true` to clear the composer.
  final Future<bool> Function(BroadcastComposeResult result) onSend;

  /// Placeholder shown in the message box.
  final String placeholder;

  final int minLines;
  final int maxLines;

  /// When supplied, a Close button is rendered next to Send.
  final VoidCallback? onClose;

  @override
  State<BroadcastComposer> createState() => BroadcastComposerState();
}

class BroadcastComposerState extends State<BroadcastComposer> {
  final TextEditingController _message = TextEditingController();
  final TextEditingController _subject = TextEditingController();
  bool _sendEmail = false;
  bool _customizeSubject = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Re-evaluate the Send button's enabled state as the user types.
    _message.addListener(_onChanged);
    _subject.addListener(_onChanged);
  }

  @override
  void dispose() {
    _message
      ..removeListener(_onChanged)
      ..dispose();
    _subject
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _customizingSubject => _sendEmail && _customizeSubject;

  bool get _canSend {
    if (_sending) return false;
    if (_message.text.trim().isEmpty) return false;
    if (_customizingSubject && _subject.text.trim().isEmpty) return false;
    return true;
  }

  Future<void> _send() async {
    if (!_canSend) return;
    setState(() => _sending = true);
    try {
      final cleared = await widget.onSend(
        BroadcastComposeResult(
          text: _message.text.trim(),
          sendEmail: _sendEmail,
          emailSubject: _customizingSubject ? _subject.text.trim() : null,
        ),
      );
      if (!mounted) return;
      if (cleared) {
        _message.clear();
        _subject.clear();
        setState(() {
          _sendEmail = false;
          _customizeSubject = false;
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_customizingSubject) ...[
          ShadInput(
            controller: _subject,
            placeholder: const Text('Subject'),
            enabled: !_sending,
          ),
          const SizedBox(height: 8),
        ],
        MarkdownComposerField(
          controller: _message,
          placeholder: widget.placeholder,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          enabled: !_sending,
        ),
        const SizedBox(height: 12),
        ShadCheckbox(
          value: _sendEmail,
          enabled: !_sending,
          onChanged: (v) => setState(() {
            _sendEmail = v;
            if (!v) _customizeSubject = false;
          }),
          label: const Text('Send email'),
        ),
        if (_sendEmail) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: ShadCheckbox(
              value: _customizeSubject,
              enabled: !_sending,
              onChanged: (v) => setState(() => _customizeSubject = v),
              label: const Text('Customize email subject'),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            const Spacer(),
            ShadButton(
              size: ShadButtonSize.sm,
              leading: const Icon(LucideIcons.send, size: 14),
              onPressed: _canSend ? _send : null,
              child: Text(_sending ? 'Sending…' : 'Send'),
            ),
            if (widget.onClose != null) ...[
              const SizedBox(width: 8),
              ShadButton.outline(
                size: ShadButtonSize.sm,
                onPressed: _sending ? null : widget.onClose,
                child: const Text('Close'),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
