import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/utils/contact_urls.dart';
import 'package:ui_lib/src/widgets/contact/contact_action_button.dart';
import 'package:ui_lib/src/widgets/contact/selectable_value.dart';

/// A person's phone number where it is displayed: the selectable number
/// with Call and WhatsApp below it. Never used inside a form.
class PhoneContact extends StatelessWidget {
  /// [number] with Call and WhatsApp.
  ///
  /// [defaultCountryCode] (digits only: `91`) completes a number stored
  /// without a country code for WhatsApp.
  const PhoneContact({
    required this.number,
    required String this.defaultCountryCode,
    super.key,
  });

  /// [number] with Call only.
  const PhoneContact.callOnly({required this.number, super.key})
    : defaultCountryCode = null;

  /// The number as it is stored.
  final String number;

  /// The club's country calling code, or null when WhatsApp is not offered.
  final String? defaultCountryCode;

  /// Label of the call button.
  static const String callLabel = 'Call';

  /// Label of the WhatsApp button.
  static const String whatsAppLabel = 'WhatsApp';

  /// Gap between the number and its buttons, and between the buttons.
  static const double gap = 8;

  @override
  Widget build(BuildContext context) {
    final countryCode = defaultCountryCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: gap,
      children: [
        SelectableValue(value: number),
        Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            ContactActionButton(
              icon: LucideIcons.phone,
              label: callLabel,
              url: ContactUrls.call(number),
            ),
            if (countryCode != null)
              ContactActionButton(
                icon: LucideIcons.messageCircle,
                label: whatsAppLabel,
                url: ContactUrls.whatsApp(
                  number,
                  defaultCountryCode: countryCode,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
