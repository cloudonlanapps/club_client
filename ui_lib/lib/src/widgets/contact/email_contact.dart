import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/utils/contact_urls.dart';
import 'package:ui_lib/src/widgets/contact/contact_action_button.dart';
import 'package:ui_lib/src/widgets/contact/selectable_value.dart';

/// A person's email address where it is displayed: the selectable address
/// with one button below it that starts an email. Never used inside a form.
class EmailContact extends StatelessWidget {
  /// [address] with a button labelled [actionLabel] that starts an email
  /// to it, with [subject] when one is given.
  const EmailContact({
    required this.address,
    required this.actionLabel,
    this.subject,
    super.key,
  });

  /// The address as it is stored.
  final String address;

  /// Label of the button.
  final String actionLabel;

  /// Subject of the email the button starts, if any.
  final String? subject;

  /// Gap between the address and its button.
  static const double gap = 8;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: gap,
      children: [
        SelectableValue(value: address),
        ContactActionButton(
          icon: LucideIcons.mail,
          label: actionLabel,
          url: ContactUrls.email(address, subject: subject),
        ),
      ],
    );
  }
}
