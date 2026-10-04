import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';

import '../utils/icon_mapper.dart';
import 'value_card.dart';

/// Values content with value cards.
class ValuesContent extends StatelessWidget {
  const ValuesContent({required this.values, super.key});
  final List<ClubValueCardData> values;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 48,
          runSpacing: 48,
          children: values
              .map(
                (value) => ValueCard(
                  icon: mapIconName(value.iconName),
                  title: value.title,
                  description: value.description,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
