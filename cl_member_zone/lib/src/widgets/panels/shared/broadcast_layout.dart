import 'package:flutter/material.dart';

/// Lays out the Broadcast screen's body: the [composer] fixed at the top and
/// the [sentList] scrolling below it (club_client#269).
///
/// With the keyboard closed, only [sentList] scrolls; the composer stays
/// where it is. With the keyboard open (a bottom inset on the [View]),
/// [sentList] is hidden and the composer takes the whole height, scrolling
/// inside it, so its last controls (the email subject checkbox, Send) can be
/// reached without closing the keyboard (club_client#168).
///
/// The composer is never taller than the space it is given: when it does not
/// fit, it scrolls, and [sentList] gives up its room first. The composer
/// keeps its place in the tree whether or not the keyboard is open, so its
/// text and focus survive the keyboard opening.
class BroadcastLayout extends StatelessWidget {
  const BroadcastLayout({
    required this.composer,
    required this.sentList,
    this.composerPadding = EdgeInsets.zero,
    this.sentListPadding = EdgeInsets.zero,
    super.key,
  });

  /// The narrowing controls and the message composer.
  final Widget composer;

  /// The broadcasts sent, as a sliver.
  final Widget sentList;

  /// The padding around [composer].
  final EdgeInsets composerPadding;

  /// The padding around [sentList].
  final EdgeInsets sentListPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Read in the layout builder, which runs again when the keyboard
        // moves and the Scaffold above resizes its body. The view's own inset
        // is read: that Scaffold takes the keyboard out of its body's
        // MediaQuery.
        final keyboardOpen = View.of(context).viewInsets.bottom > 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: constraints.maxHeight),
              child: SingleChildScrollView(
                primary: false,
                padding: composerPadding,
                child: composer,
              ),
            ),
            Expanded(
              child: keyboardOpen
                  ? const SizedBox.shrink()
                  : CustomScrollView(
                      primary: false,
                      slivers: [
                        SliverPadding(
                          padding: sentListPadding,
                          sliver: sentList,
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}
