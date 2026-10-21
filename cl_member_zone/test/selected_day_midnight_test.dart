import 'package:cl_member_zone/src/providers/selected_day.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show clManualRefreshProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Issue 206: the dashboard day turns over at local midnight', () async {
    // 0.3 s before midnight, on a clock that runs with real time: the
    // provider's own timer has to turn the day.
    final start = DateTime(2026, 10, 21, 23, 59, 59, 700);
    final running = Stopwatch()..start();
    final container = ProviderContainer(
      overrides: [
        selectedDayClockProvider.overrideWithValue(
          () => start.add(running.elapsed),
        ),
      ],
    );
    addTearDown(container.dispose);
    // Kept alive, as the dashboard panels watching it keep it.
    final sub = container.listen(selectedDayProvider, (_, _) {});
    addTearDown(sub.close);

    expect(container.read(selectedDayProvider), DateTime(2026, 10, 21));

    await Future<void>.delayed(const Duration(milliseconds: 2500));

    expect(container.read(selectedDayProvider), DateTime(2026, 10, 22));
  });

  test('Issue 206: Refresh reads the day again', () {
    var now = DateTime(2026, 10, 21, 9);
    final container = ProviderContainer(
      overrides: [selectedDayClockProvider.overrideWithValue(() => now)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(selectedDayProvider, (_, _) {});
    addTearDown(sub.close);
    expect(container.read(selectedDayProvider), DateTime(2026, 10, 21));

    now = DateTime(2026, 10, 22, 9);
    container.read(clManualRefreshProvider.notifier).state++;

    expect(container.read(selectedDayProvider), DateTime(2026, 10, 22));
  });
}
