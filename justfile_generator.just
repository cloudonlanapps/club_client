# The project generator (#186): a club's web app or website from the
# templates (cl_club_app/example, cl_club_website/example) and a brand folder.
# A deploy tool calls `generate`; club_project_generator/example_brand is a
# complete neutral brand to start from.

# e.g. just generate app club_project_generator/example_brand /tmp/exc --api-url http://localhost:8000/v1
# Further flags: --app-url, --website-url (whole URLs, as given), --no-check.
# Generate a club's web project (TARGET app|website) from a brand folder.
[group('generator')]
generate TARGET BRAND OUT *ARGS:
    #!/usr/bin/env bash
    set -euo pipefail
    brand="$(realpath -m "{{BRAND}}")"; out="$(realpath -m "{{OUT}}")"
    cd "{{justfile_directory()}}/club_project_generator"
    dart pub get >/dev/null
    dart run bin/generate.dart --target "{{TARGET}}" --brand "$brand" --out "$out" {{ARGS}}

# The generator's own tests (no Flutter build).
[group('generator')]
generator-test:
    cd club_project_generator && dart pub get >/dev/null && dart test

# Generate both targets from the example brand and build each for the web.
[group('generator')]
generator-build-example:
    #!/usr/bin/env bash
    set -euo pipefail
    tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
    brand="{{justfile_directory()}}/club_project_generator/example_brand"
    just generate app "$brand" "$tmp/app" --api-url http://localhost:8000/v1 --website-url http://localhost:8081
    (cd "$tmp/app" && flutter build web --release)
    just generate website "$brand" "$tmp/website" --api-url http://localhost:8000/v1 --app-url http://localhost:8080
    (cd "$tmp/website" && flutter build web --release)
    echo "==> both built"
