import 'package:cl_club_forms/cl_club_forms.dart'
    show InquiryChoice, InquiryForm, InquiryFormState;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clPublicInquiryProvider, defaultCountryCodeProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show InquiryKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/inquiry_form_helpers.dart';
import '../page_content/site_copy.dart';
import 'inquiry_thanks_card.dart';

/// A public inquiry: contact, or an expression of interest. The connected
/// host of [InquiryForm]: the card, its title and description, the Send
/// button and the thank-you are drawn here, and the form holds the fields.
///
/// Both kinds ask the same four things and differ in wording and in the extra
/// questions, so they are one widget.
///
/// Two anti-spam measures the server expects, neither of which a visitor sees:
///
/// * a **fill-time token**, fetched when the view appears and sent back with
///   the submission. The server drops anything returned in under three
///   seconds, on the reasoning that no human fills a form that fast — so the
///   token must be fetched when the form appears, not when it is submitted.
/// * a **honeypot**, a field of the form kept out of the layout and off the
///   tab order that a person cannot fill and a bot filling everything will.
///
/// The server answers 202 whether it kept the submission or dropped it, so a
/// caller — and a spammer — learns nothing from the response. A thank-you is
/// therefore what success looks like in both cases; only a transport failure
/// or a refusal shows an error, and it never echoes back what was typed.
class InquiryView extends ConsumerStatefulWidget {
  const InquiryView({
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
  ConsumerState<InquiryView> createState() => InquiryViewState();
}

/// State of [InquiryView]: holds the form's key, the fill-time token and how
/// far the sending got.
class InquiryViewState extends ConsumerState<InquiryView> {
  /// Key of the inquiry form.
  final formKey = GlobalKey<InquiryFormState>();

  /// Whether a submission is in flight.
  bool isSending = false;

  /// Whether the inquiry was sent; the thank-you then replaces the form.
  bool isSent = false;

  /// Fetched when the view appears, not when it is submitted: the server
  /// measures how long the visitor had it open.
  late final Future<String> token;

  @override
  void initState() {
    super.initState();
    token = ref.read(clPublicInquiryProvider.notifier).formToken();
    // A failed token fetch must not surface as an unhandled error; the
    // submit path reports it, and only if someone actually submits.
    token.ignore();
    // Likewise the club's country code (#31): asked for now, so the server
    // has answered by the time the phone is saved.
    ref.read(defaultCountryCodeProvider);
  }

  /// The Send action: validates the form and submits its values.
  Future<void> submit() async {
    final values = formKey.currentState?.validate();
    if (values == null) return;
    final strings = SiteCopy.of(context).strings;

    setState(() => isSending = true);
    try {
      await InquiryFormSubmit.create(
        notifier: ref.read(clPublicInquiryProvider.notifier),
        defaultCountryCode: ref.read(defaultCountryCodeProvider),
        kind: widget.kind,
        token: await token,
        values: values,
      );
      if (!mounted) return;
      setState(() {
        isSending = false;
        isSent = true;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => isSending = false);
      formKey.currentState?.showErrors(
        formError: InquiryFormSubmit.refusalMessage(error, strings),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isSent) {
      return InquiryThanksCard(
        title: widget.thanksTitle,
        body: widget.thanksBody,
      );
    }

    final theme = ShadTheme.of(context);
    final strings = SiteCopy.of(context).strings;

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
            InquiryForm(
              key: formKey,
              copy: buildInquiryFormCopy(
                strings: strings,
                messageLabel: widget.messageLabel,
                messagePlaceholder: widget.messagePlaceholder,
              ),
              choices: [
                for (final choice in widget.choices)
                  InquiryChoice(
                    key: choice.key,
                    label: inquiryLabelWithoutMark(choice.label),
                    placeholder: choice.placeholder,
                    options: choice.options,
                  ),
              ],
              messageRequired: widget.messageRequired,
              enabled: !isSending,
            ),
            const SizedBox(height: 24),
            ShadButton(
              width: double.infinity,
              onPressed: isSending ? null : submit,
              child: Text(
                isSending ? strings.contactFormSending : widget.submitLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
