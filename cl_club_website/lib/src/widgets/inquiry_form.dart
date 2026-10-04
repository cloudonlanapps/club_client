import 'package:cl_remote_store/cl_remote_store.dart'
    show clPublicInquiryProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../page_content/site_copy.dart';

/// One extra question a form asks beyond name, email, phone and message.
///
/// The answers travel in the inquiry's `extra` map, which the server stores
/// as-is; [key] is what an admin reading the inquiry sees.
class InquiryChoice {
  const InquiryChoice({
    required this.key,
    required this.label,
    required this.placeholder,
    required this.options,
  });

  final String key;
  final String label;
  final String placeholder;

  /// Wire value to the label shown for it.
  final Map<String, String> options;
}

/// A public inquiry form: contact, or an expression of interest.
///
/// Both kinds ask the same four things and differ in wording and in the extra
/// questions, so they are one widget.
///
/// Two anti-spam measures the server expects, neither of which a visitor sees:
///
/// * a **fill-time token**, fetched when the form is built and sent back with
///   the submission. The server drops anything returned in under three
///   seconds, on the reasoning that no human fills a form that fast — so the
///   token must be fetched when the form appears, not when it is submitted.
/// * a **honeypot**, a field kept out of the layout and off the tab order that
///   a person cannot fill and a bot filling everything will.
///
/// The server answers 202 whether it kept the submission or dropped it, so a
/// caller — and a spammer — learns nothing from the response. A thank-you is
/// therefore what success looks like in both cases; only a transport or
/// validation failure shows an error, and it never echoes back what was typed.
class InquiryForm extends ConsumerStatefulWidget {
  const InquiryForm({
    required this.kind,
    required this.title,
    required this.description,
    required this.messageLabel,
    required this.messagePlaceholder,
    required this.submitLabel,
    required this.thanksTitle,
    required this.thanksBody,
    super.key,
    this.messageRequired = true,
    this.choices = const [],
  });

  final InquiryKind kind;
  final String title;
  final String description;
  final String messageLabel;
  final String messagePlaceholder;
  final String submitLabel;
  final String thanksTitle;
  final String thanksBody;

  /// Whether a message is required. A contact form is a message; an interest
  /// form is a set of answers with an optional note.
  final bool messageRequired;

  final List<InquiryChoice> choices;

  @override
  ConsumerState<InquiryForm> createState() => _InquiryFormState();
}

enum _FormState { editing, sending, sent }

class _InquiryFormState extends ConsumerState<InquiryForm> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _message = TextEditingController();
  final _honeypot = TextEditingController();
  final _answers = <String, String>{};

  _FormState _state = _FormState.editing;
  String? _error;

  /// Fetched when the form appears, not when it is submitted: the server
  /// measures how long the visitor had it open.
  late final Future<String> _token;

  @override
  void initState() {
    super.initState();
    _token = ref.read(clPublicInquiryProvider.notifier).formToken();
    // A failed token fetch must not surface as an unhandled error; the
    // submit path reports it, and only if someone actually submits.
    _token.ignore();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _message.dispose();
    _honeypot.dispose();
    super.dispose();
  }

  Future<void> _submit(SiteStrings strings) async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final message = _message.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        (widget.messageRequired && message.isEmpty)) {
      setState(() => _error = strings.contactFormErrorRequired);
      return;
    }
    // Deliberately loose: an address the server cannot deliver to is the
    // server's to find out, and a stricter pattern rejects real addresses.
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = strings.contactFormErrorEmail);
      return;
    }

    setState(() {
      _state = _FormState.sending;
      _error = null;
    });

    try {
      final token = await _token;
      await ref
          .read(clPublicInquiryProvider.notifier)
          .submit(
            kind: widget.kind,
            name: name,
            email: email,
            message: message,
            token: token,
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            extra: _answers.isEmpty ? null : Map.of(_answers),
            website: _honeypot.text.isEmpty ? null : _honeypot.text,
          );
      if (mounted) setState(() => _state = _FormState.sent);
    } on ServerException catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _FormState.editing;
        _error = e.statusCode == 429
            ? strings.contactFormErrorRateLimited
            : strings.contactFormErrorGeneric;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _state = _FormState.editing;
        _error = strings.contactFormErrorGeneric;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final strings = SiteCopy.of(context).strings;

    if (_state == _FormState.sent) {
      return ShadCard(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                LucideIcons.circleCheck,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(widget.thanksTitle, style: theme.textTheme.h3),
              const SizedBox(height: 8),
              Text(
                widget.thanksBody,
                style: theme.textTheme.muted,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final sending = _state == _FormState.sending;

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: theme.textTheme.h3),
            const SizedBox(height: 8),
            Text(widget.description, style: theme.textTheme.muted),
            const SizedBox(height: 24),

            _label(theme, strings.contactFormNameLabel),
            ShadInput(
              controller: _name,
              enabled: !sending,
              placeholder: Text(strings.contactFormNamePlaceholder),
            ),
            const SizedBox(height: 20),

            _label(theme, strings.contactFormEmailLabel),
            ShadInput(
              controller: _email,
              enabled: !sending,
              keyboardType: TextInputType.emailAddress,
              placeholder: Text(strings.contactFormEmailPlaceholder),
            ),
            const SizedBox(height: 20),

            _label(theme, strings.contactFormPhoneLabel),
            ShadInput(
              controller: _phone,
              enabled: !sending,
              keyboardType: TextInputType.phone,
              placeholder: Text(strings.contactFormPhonePlaceholder),
            ),
            const SizedBox(height: 20),

            for (final choice in widget.choices) ...[
              _label(theme, choice.label),
              ShadSelect<String>(
                enabled: !sending,
                placeholder: Text(choice.placeholder),
                options: [
                  for (final entry in choice.options.entries)
                    ShadOption(value: entry.key, child: Text(entry.value)),
                ],
                selectedOptionBuilder: (context, value) =>
                    Text(choice.options[value] ?? value),
                onChanged: (value) {
                  if (value != null) _answers[choice.key] = value;
                },
              ),
              const SizedBox(height: 20),
            ],

            _label(theme, widget.messageLabel),
            ShadInput(
              controller: _message,
              enabled: !sending,
              placeholder: Text(widget.messagePlaceholder),
              minLines: 4,
              maxLines: 6,
            ),

            // The honeypot. Zero-sized and excluded from semantics and the tab
            // order, so nothing a person uses can reach it.
            ExcludeSemantics(
              child: SizedBox.shrink(
                child: Offstage(
                  child: TextField(
                    controller: _honeypot,
                    focusNode: FocusNode(
                      skipTraversal: true,
                      canRequestFocus: false,
                    ),
                    decoration: const InputDecoration(labelText: 'Website'),
                  ),
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.destructive,
                ),
              ),
            ],

            const SizedBox(height: 24),
            ShadButton(
              width: double.infinity,
              onPressed: sending ? null : () => _submit(strings),
              child: Text(
                sending ? strings.contactFormSending : widget.submitLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(ShadThemeData theme, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w500),
    ),
  );
}
