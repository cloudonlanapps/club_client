import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Keeps a text field's focus while a touch outside it scrolls the page, and
/// drops it only on a tap (#159).
///
/// Flutter's default on a mobile browser unfocuses a text field on the
/// pointer-down of any touch outside it, so starting to scroll a long form
/// closes the keyboard. Placed above the app, this overrides the two
/// tap-outside intents every [EditableText] invokes:
///
/// * a touch outside does nothing when it goes down; when it comes up less
///   than [kTouchSlop] from where it went down (a tap, not a drag), the field
///   loses the focus, but only where [unfocusOnTouchTap] is true (a mobile
///   browser by default; a native app keeps touch from unfocusing at all);
/// * a mouse, stylus or other pointer outside unfocuses on its down event,
///   as before.
class ScrollSafeTapOutside extends StatefulWidget {
  /// Wraps [child], usually the app's root `ShadApp`.
  const ScrollSafeTapOutside({
    required this.child,
    this.unfocusOnTouchTap = kIsWeb,
    super.key,
  });

  /// The app.
  final Widget child;

  /// Whether a touch tap outside a field drops its focus. On by default on
  /// the web, where a phone's browser expects it; off in a native app, where
  /// Flutter never unfocuses on a touch outside.
  final bool unfocusOnTouchTap;

  @override
  State<ScrollSafeTapOutside> createState() => ScrollSafeTapOutsideState();
}

/// Remembers where each touch outside a field went down, to tell a tap from
/// a drag when it comes up.
class ScrollSafeTapOutsideState extends State<ScrollSafeTapOutside> {
  /// Where each touch pointer outside a field went down, by pointer id.
  final Map<int, Offset> touchDownPositions = {};

  /// A pointer went down outside the focused field.
  void onTapOutsideDown(EditableTextTapOutsideIntent intent) {
    final event = intent.pointerDownEvent;
    if (event.kind == PointerDeviceKind.touch) {
      touchDownPositions[event.pointer] = event.position;
      return;
    }
    intent.focusNode.unfocus();
  }

  /// A pointer came up outside the focused field.
  void onTapOutsideUp(EditableTextTapUpOutsideIntent intent) {
    final event = intent.pointerUpEvent;
    final down = touchDownPositions.remove(event.pointer);
    if (down == null || !widget.unfocusOnTouchTap) return;
    if ((event.position - down).distance < kTouchSlop) {
      intent.focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        EditableTextTapOutsideIntent:
            CallbackAction<EditableTextTapOutsideIntent>(
              onInvoke: onTapOutsideDown,
            ),
        EditableTextTapUpOutsideIntent:
            CallbackAction<EditableTextTapUpOutsideIntent>(
              onInvoke: onTapOutsideUp,
            ),
      },
      child: widget.child,
    );
  }
}
