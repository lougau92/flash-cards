# LLM Summary Lab

LLM Summary Lab is a Flutter proof of concept for comparing text summaries across providers and models. Each saved run includes the input, prompts, selected settings, result, latency, provider-reported token usage, status, and—when returned—the model that served the request and its finish reason.

## Providers

- OpenRouter
- Google Gemini
- Mistral AI
- GroqCloud

OpenRouter, Mistral, and Groq use a shared OpenAI-compatible chat service. Gemini uses its native `generateContent` API. Requests are not automatically retried, so each saved attempt reflects one provider call.

## API keys

Create `app/.env` from `app/env.example` and put local default keys in it. The app reads those defaults at startup. You can inspect them in **Configure API Keys**; the fields are masked until revealed and show which values came from `.env`. Non-empty values saved in the settings sheet take precedence over `.env`; clearing a saved value restores the built-in default.

Flutter bundles `.env` into the application because this is a local research prototype. Anyone who receives an installed build can extract its built-in keys. The app preference store is also not a secure credential vault. Use dedicated, low-limit keys and do not distribute a build containing private credentials. A public release should call a backend that keeps provider credentials off the client.

Never commit a real `.env` file. The checked-in `env.example` contains empty values and is not bundled.

## Run locally

```sh
cd app
cp env.example .env
# Add keys to .env, then:
flutter pub get
flutter run
```

## Supabase run history

Run history uses local storage until both `SUPABASE_URL` and
`SUPABASE_PUBLISHABLE_KEY`
are set in `.env`. For remote history:

1. Create a Supabase project and copy its project URL and publishable API key
   into those two `.env` entries. Never put a Supabase secret API key in this
   Flutter app; secret keys belong only in trusted server environments.
2. Run both SQL migrations in `supabase/migrations` in the Supabase SQL editor.
3. Enable email/password sign-in in Supabase Auth. Enable anonymous sign-ins
   too, so people can submit feedback from the sign-in screen without creating
   an account. Consider enabling CAPTCHA to reduce anonymous sign-in abuse.
   Sign in with the same account on each device that should share history.

The migration enables row-level security and limits every run operation to the
signed-in owner. Run records include full source text, prompts, and summaries,
so only use remote history for data approved for your Supabase project and
research policy. A local `.env` is ignored by Git; the public Supabase key is
still bundled into the client, where it is protected by Auth and database
policies rather than secrecy. Supabase secret API keys bypass row-level
security and must remain on a trusted backend.

Feedback is stored in the `app_feedback` table with row-level security. Signed-in
users and anonymous users can submit feedback; the app cannot read or edit the
inbox. Anonymous feedback sessions are created on first submission.

## Model catalog

The model picker can sort by name and by metadata returned from a provider,
such as modality, context size, catalog date, and price. OpenRouter shows free
models by default; use **Include paid models** to add paid options. A sort field
is offered only when the loaded model list includes that metadata.

## Error log

The bug-report icon opens the local diagnostic log. It records uncaught Flutter
and Dart errors plus handled provider, storage, import, authentication, and
settings failures. The most recent 100 entries are retained on this device.
Export creates a JSON file; API keys and token-like values are redacted before
recording. Review the file before sharing it because exception messages and
stack traces can still contain environment-specific details.

## Tests

Run `flutter test` from the `app` directory. Provider contract tests use mocked HTTP responses, so they do not require API keys or contact live providers. They check each provider's model-list response, request format, output parsing, token metadata, and failed HTTP responses.

## Research workflow

1. Select a provider and refresh its available text models.
2. Load or paste source text, edit the system and instruction prompts, and set temperature and output-token limit.
3. Run a summary. Successful and failed provider attempts are retained in local
history or in the signed-in Supabase account when configured.
4. Select up to four runs in history to compare their models, input preview, prompts, settings, output, latency, token counts, and finish reason.

Run history stores the complete source text and prompt in the configured store. The text and prompts are also sent to the selected provider when you run a request. Token estimates shown before a run are approximate; final counts come from provider responses when available. Model availability, pricing, and serving routes can change over time, so retain the saved run metadata when reporting an experiment.

The file picker accepts text, Markdown, JSON, and PDF files. PDF extraction is a lightweight fallback and may not read scanned, compressed, or complex PDFs accurately; verify imported text before using it in an experiment.
