# Flutter app workspace task runner.
#
# Test suites are split into justfile_<name>.just modules (imported below).
# The SDK and its server-backed integration suite live in
# cloudonlanapps/club_sdk (checked out at the workspace's packages/club_sdk);
# run those recipes there. The remaining legacy recipes (build/run/deploy,
# mac/web/android app-integration) are parked verbatim in extra.just, NOT
# imported yet.

import 'justfile_unit_tests.just'
import 'justfile_app_tests.just'
import 'justfile_generator.just'

default:
    @just --list
