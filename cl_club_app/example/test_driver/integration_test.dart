// Driver entry point for `flutter drive` based web/desktop runs.
//
// The integration_test files themselves work unchanged with both
// `flutter test integration_test/...` (used for native runs) and
// `flutter drive --driver=test_driver/integration_test.dart \
//                --target=integration_test/<file>.dart -d chrome`
// (used for browser runs, which can't be launched via `flutter test`).
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
