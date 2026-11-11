# flash-cards

The Flutter app and development instructions are in [app/README.md](app/README.md).

Check the latest user feedback with:

```sh
(cd app && dart run app_feedback:feedback)
```

The [feedback skill](.agents/skills/check-feedback/SKILL.md) documents setup,
date filters, and credential handling for future agents and sessions.

Feedback UI, submission, and reader tooling use the standalone `app-feedback`
Git dependency, pinned in `app/pubspec.yaml`. Local development uses the ignored
`app/pubspec_overrides.yaml` to point directly to `../../app-feedback`; changes
in that checkout are shared immediately with `vma-running` without vendor copies.
Run `flutter pub get` in `app/` after changing dependency configuration. The
shared repository must be published and accessible for clean CI builds.
