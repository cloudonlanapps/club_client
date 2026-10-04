import 'package:club_sdk_2/club_sdk_2.dart' show Inquiry;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'inquiry_detail.dart';

/// The widest the inquiry sheet grows on a large screen.
const double inquirySheetMaxWidth = 520;

/// Opens [inquiry] in full in a side sheet over the inbox. A modal the row
/// opens, so no route is involved and closing it returns to the same page
/// of the inbox, already updated through the master.
Future<void> showInquirySheet(BuildContext context, Inquiry inquiry) {
  return showShadSheet<void>(
    context: context,
    side: ShadSheetSide.right,
    builder: (context) {
      final size = MediaQuery.sizeOf(context);
      return ShadSheet(
        scrollable: false,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(
          maxWidth: size.width < inquirySheetMaxWidth
              ? size.width
              : inquirySheetMaxWidth,
        ),
        child: SizedBox(
          height: size.height,
          child: InquiryDetail(inquiry: inquiry),
        ),
      );
    },
  );
}
