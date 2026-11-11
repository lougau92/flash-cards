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

## Deploy the PWA

[Deploy PWA to GitHub Pages](.github/workflows/deploy_pwa.yml) runs on pushes to
`main` and manually from Actions. Like VMA Running, it publishes the release
build to `gh-pages`, at <https://lougau92.github.io/flash-cards/>.

One-time repository setup:

1. Add an Actions secret named `APP_FEEDBACK_DEPLOY_KEY`: a private SSH deploy
   key with read access to `lougau92/app-feedback`. CI checks out the exact
   commit pinned in `app/pubspec.yaml` and uses a temporary path override.
2. Optionally add Actions **variables** `SUPABASE_URL` and
   `SUPABASE_PUBLISHABLE_KEY` (the `sb_publishable_...` key). Set both or neither.
   With neither, the app uses local history and feedback is unavailable.
3. Run the workflow. Once it creates `gh-pages`, select **Settings → Pages →
   Deploy from a branch → gh-pages → / (root)**. Allow Actions read/write
   repository permissions if organization policy restricts them.

CI creates a fresh `.env` from `app/env.example` with empty provider API keys;
users enter their own keys in the app settings. Local `.env` files are never
used for deployment. The optional Supabase settings are public client
configuration and are included in the downloadable build.

The pipeline runs Flutter tests, builds under `/flash-cards/`, generates a
content-versioned offline cache, and checks a real browser can reload the app
offline before publishing. CanvasKit is bundled locally. Only shipped static
assets are cached; provider and Supabase requests remain online operations.
The app shell and local history can be used offline after installation; cloud
history, feedback, model catalogs, and summary generation need a connection.
An open app reloads when an updated worker takes control.

To verify a release locally, start with a disposable checkout containing an
empty `.env` (builds bundle it), then run:

```sh
(cd app && flutter build web --release --base-href /flash-cards/ --no-web-resources-cdn)
python3 tool/prepare_pwa.py app/build/web
npm ci
npx playwright install chromium
npm run test:pwa
```

The pipeline pins Flutter 3.47.5. Update the pin alongside a verified release
build when upgrading Flutter. Web initialization uses Flutter's current
[bootstrap entry point](https://docs.flutter.dev/platform-integration/web/initialization);
GitHub documents the [branch publishing settings](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site).
