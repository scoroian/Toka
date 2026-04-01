# patches/

This directory contains local overrides for packages with published bugs that
block the build.

## analyzer_plugin (0.12.0)

**Bug:** `TopLevelDeclarations.publiclyExporting2()` is called in
`lib/src/utilities/change_builder/change_builder_dart.dart` but this method
does not exist in any published version of the `analyzer` package.

**Affects:** `custom_lint` and `riverpod_lint` (which depend on
`analyzer_plugin` transitively via `custom_lint_core`).

**Fix:** Two call sites replaced — `publiclyExporting2(element)` →
`publiclyExporting(element)` — using the method that actually exists in
`analyzer ^7.0.0`.

**Removal:** Once `analyzer_plugin` publishes a version that fixes this bug,
remove the `dependency_overrides` entry from `pubspec.yaml` and delete this
directory. Check https://github.com/dart-lang/sdk/issues for status.

**Do NOT run `dart pub get` inside `patches/analyzer_plugin/` directly** —
its own `pubspec.yaml` references sibling directories from the upstream
monorepo that do not exist here.
