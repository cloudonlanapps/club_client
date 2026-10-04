import '../models/evaluation_item_kind.dart';
import '../models/evaluation_layout_entry.dart';

/// The closing run of a layout: the Q & A items at its end, outside any
/// section (a summary, strengths, a private note). Every view keeps the
/// template's order and shows that run after the rest, outside any section,
/// as one untitled card; a Q & A anywhere else stays where the template puts
/// it.
abstract final class EvaluationClosingRun {
  /// The index in [layout] where the closing run starts; `layout.length`
  /// when the layout does not end in a top-level Q & A.
  static int start(List<EvaluationLayoutEntry> layout) {
    var i = layout.length;
    while (i > 0 && layout[i - 1].item?.kind == EvaluationItemKind.qa) {
      i--;
    }
    return i;
  }
}
