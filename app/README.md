# app

Project File Structure
Plaintext
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── default_prompts.dart
│   │   └── provider_configs.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── utils/
│       ├── file_helper.dart
│       └── clipboard_helper.dart
├── models/
│   ├── llm_provider_type.dart
│   ├── llm_model_info.dart
│   ├── summary_request.dart
│   └── summary_run.dart
├── services/
│   ├── storage/
│   │   ├── storage_service_interface.dart
│   │   └── local_run_storage.dart
│   └── llm/
│       ├── llm_service_interface.dart
│       ├── openrouter_service.dart
│       ├── gemini_service.dart
│       ├── mistral_service.dart
│       └── groq_service.dart
├── state/
│   ├── runner_notifier.dart
│   ├── history_notifier.dart
│   └── settings_notifier.dart
└── ui/
    ├── screens/
    │   ├── main_layout_screen.dart
    │   ├── runner_screen.dart
    │   ├── history_screen.dart
    │   └── comparison_screen.dart
    └── widgets/
        ├── input_source_selector.dart
        ├── prompt_editor.dart
        ├── provider_model_selector.dart
        ├── run_card.dart
        ├── parameter_drawer.dart
        └── comparison_view.dart
Step-by-Step Implementation Plan
Phase 1: Models & Data Layer
models/llm_provider_type.dart

Define LLMProviderType enum (openRouter, gemini, mistral, groq).

Add metadata extensions for display names, default base URLs, and API key requirement flags.

models/llm_model_info.dart

Model representing available models per provider (ID, display name, max context tokens, cost tags, free model boolean).

models/summary_request.dart

Encapsulate parameters: source text, input file name (if applicable), system prompt, instruction prompt, temperature, max tokens, target model ID, provider type.

models/summary_run.dart

Encapsulate output results: unique run ID, timestamp, complete SummaryRequest, generated output text, execution time in milliseconds, token usage stats, status (success/error), and error message.

Include jsonEncode/jsonDecode methods for local disk serialization.

Phase 2: Utilities & Core Local Services
core/utils/file_helper.dart

Implement cross-platform file picking using file_picker for .txt, .md, .json, and .pdf files.

Read plain text contents safely across Mobile, Desktop, and Web.

core/utils/clipboard_helper.dart

Implement clipboard paste handler using standard Clipboard.getData(Clipboard.kTextPlain).

services/storage/storage_service_interface.dart & local_run_storage.dart

Define interface and concrete implementation using path_provider to write/read JSON files to an app_runs/ subfolder on local disk.

Implement saveRun(SummaryRun run), getAllRuns(), deleteRun(String id), and clearAllRuns().

Phase 3: Polymorphic LLM API Integrations
services/llm/llm_service_interface.dart

Define abstract class LLMServiceInterface with methods fetchAvailableModels() and generateSummary(SummaryRequest request).

services/llm/openrouter_service.dart

Implement OpenRouter REST integration; handle custom headers (HTTP-Referer, X-Title) and free model filtering logic.

services/llm/gemini_service.dart

Implement direct Google Gemini API integration (supporting system instructions and temperature controls).

services/llm/mistral_service.dart & groq_service.dart

Implement Open-AI format compatible endpoints for Mistral AI and GroqCloud APIs.

Phase 4: State Management
state/runner_notifier.dart

Manage current workspace state: selected input source, raw input text, active prompt, selected provider/model, temperature slider state, loading indicator, and latest run output.

state/history_notifier.dart

Manage local run history list, filtering (by provider, model, or keyword), search queries, and selected runs for side-by-side comparison.

state/settings_notifier.dart

Persist provider API keys securely in local application settings.

Phase 5: Primary UI (Runner & Configuration)
ui/widgets/input_source_selector.dart

Segmented UI/Buttons to toggle between "Upload File" and "Paste Clipboard", including source preview details (file name, character count, token estimate).

ui/widgets/prompt_editor.dart

Expandable multi-line text editor with preset prompt templates (e.g., "3 Bullet Points", "Executive Summary", "Key Takeaways Only") and reset capabilities.

ui/widgets/provider_model_selector.dart

Dropdown pickers for selecting active provider and populated models list with badges for "Free" or "Paid" endpoints.

ui/screens/runner_screen.dart

Main workspace UI putting together input, prompt configuration, model parameters, execution button, real-time output panel, and response metadata (latency, output length).

Phase 6: Run History & Comparison UI
ui/widgets/run_card.dart

Card widget displaying historical run summaries: model used, prompt snippet, execution latency, timestamp, and selection checkbox for comparison.

ui/screens/history_screen.dart

ListView displaying saved test runs loaded from disk with filtering controls and quick deletion options.

ui/screens/comparison_screen.dart & ui/widgets/comparison_view.dart

Split-screen / grid view allowing users to select 2–4 past runs and compare input parameters, execution speed, model output, and formatting side-by-side.
