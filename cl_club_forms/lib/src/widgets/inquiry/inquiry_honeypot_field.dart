import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'inquiry_form_fields.dart';

/// The honeypot of an inquiry form: a field a person cannot fill and a bot
/// filling everything will.
///
/// A field of the form like the others, so its value travels with them, but
/// offstage and excluded from the focus order and from semantics, so
/// nothing a person uses can reach it. It takes no room.
class InquiryHoneypotField extends StatelessWidget {
  const InquiryHoneypotField({super.key});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ExcludeFocus(
        child: Offstage(
          child: ShadInputFormField(id: InquiryFormFields.honeypotId),
        ),
      ),
    );
  }
}
