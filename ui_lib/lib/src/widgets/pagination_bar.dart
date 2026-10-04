import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class PaginationBar extends StatelessWidget {
  const PaginationBar({
    required this.total,
    required this.limit,
    required this.offset,
    super.key,
    this.onPrevious,
    this.onNext,
  });
  final int total;
  final int limit;
  final int offset;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final start = total == 0 ? 0 : offset + 1;
    final end = (offset + limit) > total ? total : (offset + limit);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing $start–$end of $total',
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShadButton.outline(
              onPressed: offset > 0 ? onPrevious : null,
              child: const Text('Previous'),
            ),
            const SizedBox(width: 8),
            ShadButton.outline(
              onPressed: (offset + limit) < total ? onNext : null,
              child: const Text('Next'),
            ),
          ],
        ),
      ],
    );
  }
}
