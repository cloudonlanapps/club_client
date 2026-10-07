import 'package:cl_club_forms/cl_club_forms.dart' show UserFormAssembly;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show PhoneContact, PhoneNumber;

/// A member's emergency contact on their profile.
///
/// A stored value (`Name (Relation) : Phone`) that holds a number is shown
/// in its parts: the name and relation as text, and the number with a Call
/// button. Any other value stays as the plain text it is.
class EmergencyContactValue extends StatelessWidget {
  /// The emergency contact stored as [value].
  const EmergencyContactValue({required this.value, super.key});

  /// The emergency contact as it is stored.
  final String value;

  /// Gap between the name and the number.
  static const double gap = 4;

  @override
  Widget build(BuildContext context) {
    final style = ShadTheme.of(context).textTheme.p;
    final parts = UserFormAssembly.parseEmergencyContact(value);
    final phone = parts.phone;
    if (phone == null || !PhoneNumber.isDialable(phone)) {
      return Text(value, style: style);
    }
    final name = parts.name;
    final relation = parts.relation;
    final who = [?name, if (relation != null) '($relation)'].join(' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: gap,
      children: [
        if (who.isNotEmpty) Text(who, style: style),
        PhoneContact.callOnly(number: phone),
      ],
    );
  }
}
