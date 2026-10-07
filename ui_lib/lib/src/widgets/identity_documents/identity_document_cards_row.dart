import 'package:flutter/material.dart';

import '../../constants/identity_document_sizes.dart';

/// Lays the identity-document [cards] out in one row.
///
/// A single card with nothing uploaded yet ([centred]) sits in the middle at
/// half the row's width. Otherwise the row has [slotCount] equal places,
/// filled from the left, so the geometry stays the same as cards come and go.
class IdentityDocumentCardsRow extends StatelessWidget {
  const IdentityDocumentCardsRow({
    required this.cards,
    required this.slotCount,
    required this.centred,
    super.key,
  });

  /// The cards, in order.
  final List<Widget> cards;

  /// How many places the row has.
  final int slotCount;

  /// Whether the one card stands alone in the middle.
  final bool centred;

  @override
  Widget build(BuildContext context) {
    if (centred) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Expanded(
            flex: IdentityDocumentSizes.emptyAddCardFlex,
            child: cards.first,
          ),
          const Spacer(),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: IdentityDocumentSizes.cardGap,
      children: [
        for (var i = 0; i < slotCount; i++)
          Expanded(
            child: i < cards.length ? cards[i] : const SizedBox.shrink(),
          ),
      ],
    );
  }
}
