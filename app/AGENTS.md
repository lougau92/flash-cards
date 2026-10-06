# App code instructions

These instructions apply to everything under `app/` unless a more specific
`AGENTS.md` overrides them.

## Size limits

Keep Dart source within these limits:

- **File:** at most 200 physical lines.
- **Class or enum:** at most 150 physical lines, including members.
- **Function, method, or constructor:** at most 50 physical lines, from its
  declaration through its closing brace. For expression-bodied functions,
  count the declaration and expression as one line each.

Count blank lines and comments as physical lines. If a change would exceed a
limit, split the code into focused files, classes, or private helper functions
before adding more behavior. When modifying existing code that exceeds a
limit, reduce it below the limit as part of that change where practical; do
not make an oversized unit larger.

## Dart and Flutter conventions

- Follow `analysis_options.yaml` and run `dart format` on changed Dart files.
- Avoid broad imports. Use `show` to import only the symbols used from a
  library; use `hide` only when `show` is impractical.
- Keep UI widgets focused on presentation; put state transitions in notifiers
  and provider/network I/O in services.
- Keep provider request and response handling independently testable. Add or
  update contract tests when changing a provider's I/O behavior.
- Prefer small named helpers over deeply nested widget trees or conditionals.
- Keep secrets out of source control. Read development API keys from the
  configured `.env` asset and never include key values in logs or test output.
- Preserve cross-platform behavior, especially for file picking and storage.
