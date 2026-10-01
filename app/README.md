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

## Tests

Run `flutter test` from the `app` directory. Provider contract tests use mocked HTTP responses, so they do not require API keys or contact live providers. They check each provider's model-list response, request format, output parsing, token metadata, and failed HTTP responses.

## Research workflow

1. Select a provider and refresh its available text models.
2. Load or paste source text, edit the system and instruction prompts, and set temperature and output-token limit.
3. Run a summary. Successful and failed provider attempts are retained in local history.
4. Select up to four runs in history to compare their models, input preview, prompts, settings, output, latency, token counts, and finish reason.

Run history stores the complete source text and prompt locally. The text and prompts are also sent to the selected provider when you run a request. Token estimates shown before a run are approximate; final counts come from provider responses when available. Model availability, pricing, and serving routes can change over time, so retain the saved run metadata when reporting an experiment.

The file picker accepts text, Markdown, JSON, and PDF files. PDF extraction is a lightweight fallback and may not read scanned, compressed, or complex PDFs accurately; verify imported text before using it in an experiment.
