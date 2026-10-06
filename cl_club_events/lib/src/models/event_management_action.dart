import 'package:flutter/foundation.dart' show VoidCallback;

/// One button of the Event Management card: its label and what it does.
/// A `null` `onPressed` shows the button disabled.
typedef EventManagementAction = ({String label, VoidCallback? onPressed});
