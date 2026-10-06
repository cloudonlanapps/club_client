import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/utils/launch_contact_url.dart';

/// An outline button, icon and text, that opens a contact link ([url]) in
/// the app that handles it.
class ContactActionButton extends StatelessWidget {
  /// A button labelled [label] under [icon] that opens [url].
  const ContactActionButton({
    required this.icon,
    required this.label,
    required this.url,
    super.key,
  });

  /// The action's icon.
  final IconData icon;

  /// The action's name.
  final String label;

  /// The `tel:`, `mailto:` or WhatsApp link the button opens.
  final String url;

  /// Size of the icon.
  static const double iconSize = 16;

  @override
  Widget build(BuildContext context) {
    return ShadButton.outline(
      size: ShadButtonSize.sm,
      leading: Icon(icon, size: iconSize),
      onPressed: () => launchContactUrl(url),
      child: Text(label),
    );
  }
}
