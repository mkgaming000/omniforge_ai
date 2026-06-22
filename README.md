# OmniForge AI

> One App. Every AI.

The most advanced AI Super App for Android. Combines 20+ LLM providers, image generators, video generators, music studios, code IDE, terminal, runtime, MCP tools, AI agents, document AI, voice assistant, and deep research into a single, beautiful, production-grade Flutter application.

## CI/CD Status

![CI](https://github.com/omniforge-ai/omniforge_ai/actions/workflows/ci.yml/badge.svg?branch=main)
![Code Quality](https://github.com/omniforge-ai/omniforge_ai/actions/workflows/code-quality.yml/badge.svg?branch=main)
![Build APK](https://github.com/omniforge-ai/omniforge_ai/actions/workflows/build-apk.yml/badge.svg)
![Build AAB](https://github.com/omniforge-ai/omniforge_ai/actions/workflows/build-aab.yml/badge.svg)
![Release](https://github.com/omniforge-ai/omniforge_ai/actions/workflows/release.yml/badge.svg)
![Dependabot](https://img.shields.io/badge/dependabot-enabled-025E8C?logo=dependabot)
![License](https://img.shields.io/badge/license-Proprietary-red)
![Flutter](https://img.shields.io/badge/Flutter-3.24.5-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.5-0175C2?logo=dart)
![Android](https://img.shields.io/badge/Android-14+-3DDC84?logo=android)
![Min SDK](https://img.shields.io/badge/min%20SDK-23-00E676)

## Architecture

OmniForge AI follows **Clean Architecture** with strict separation of concerns:

```
lib/
├── core/                    # Cross-cutting concerns
│   ├── config/             # App configuration
│   ├── constants/          # App-wide constants + AI provider catalog
│   ├── errors/             # Failure types + error handler
│   ├── extensions/         # Dart extensions
│   ├── network/            # Dio HTTP client + connectivity
│   ├── security/           # Encryption + biometric services
│   ├── theme/              # Material 3 theme + glassmorphism
│   ├── utils/              # Utilities
│   └── validators/         # Input validators
├── data/                    # Data layer
│   ├── models/             # DTOs ( HiveType entities )
│   ├── repositories/       # Repository implementations
│   ├── services/           # External services (AI providers, storage)
│   └── sources/            # Remote/local data sources
├── domain/                  # Domain layer
│   ├── entities/           # Business entities (HiveType)
│   ├── repositories/       # Repository interfaces
│   └── usecases/           # Use cases (application logic)
├── presentation/           # Presentation layer
│   ├── blocs/              # BLoC state management
│   ├── pages/              # Top-level pages (splash, shell)
│   ├── routes/             # GoRouter configuration
│   └── widgets/            # Shared widgets
├── features/               # Feature modules
│   ├── chat/               # Chat AI (multi-model)
│   ├── image/              # Image generation studio
│   ├── video/              # Video generation studio
│   ├── music/              # Music generation studio
│   ├── code/               # Code AI (IDE)
│   ├── terminal/           # Termux-style terminal
│   ├── runtime/            # Run code in 15+ languages
│   ├── files/              # File explorer + cloud sync
│   ├── mcp/                # MCP tool marketplace
│   ├── agents/             # AI agent builder
│   ├── documents/          # Document AI
│   ├── voice/              # Voice assistant
│   ├── search/             # Deep research
│   └── settings/           # Settings, API keys, usage, security
├── injection/              # Dependency injection (GetIt)
├── app.dart                # Root widget
└── main.dart               # Entry point
```

## AI Provider Support

### Chat Models
| Provider | Models | Streaming | Vision | Tools |
|----------|--------|-----------|--------|-------|
| OpenAI | GPT-4o, GPT-4o Mini, o1, o3 | ✅ | ✅ | ✅ |
| Anthropic | Claude 3.5 Sonnet v2, Opus, Haiku | ✅ | ✅ | ✅ |
| Google | Gemini 2.0 Flash, 1.5 Pro/Flash | ✅ | ✅ | ✅ |
| xAI | Grok 2, Grok 2 Vision, Grok Beta | ✅ | ✅ | ✅ |
| DeepSeek | DeepSeek-V3, DeepSeek-R1 | ✅ | ❌ | Partial |
| Mistral | Mistral Large 2, Codestral, Mixtral | ✅ | ✅ | ✅ |
| Alibaba | Qwen Max/Plus/Turbo, Qwen-Coder, Qwen-VL | ✅ | ✅ | ✅ |
| OpenRouter | 300+ models via unified API | ✅ | ✅ | ✅ |
| HuggingFace | Llama 3.3 70B, Mistral 7B, Qwen 2.5 72B, DeepSeek-V3 | ✅ | ❌ | ❌ |
| Ollama | Local Llama, Mistral, Phi-3, Qwen | ✅ | ❌ | ❌ |
| LM Studio | Any local GGUF model | ✅ | ❌ | ❌ |

### Image Models
- **OpenAI**: DALL-E 3, DALL-E 2, GPT Image 1
- **Stability AI**: SDXL 1.0, SD 3 Large, Stable Image Ultra/Core
- **FLUX**: FLUX 1.1 Pro, Dev, Schnell, Pro Canny/Depth
- **Ideogram**: v2, v2 Turbo, v1 (superior text rendering)
- **Recraft**: Recraft v3 (SVG + upscale + bg removal)
- **Leonardo**: Phoenix, Lightning XL, Vision XL

### Video Models
- **Runway**: Gen-3 Alpha Turbo, Gen-3 Alpha, Gen-2
- **Pika**: Pika 1.5, Pika 1.0
- **Luma**: Ray 2, Ray 1.6, Dream Machine
- **Kling**: Kling 1.6 Pro, 1.5 Pro, 1.0
- **Google Veo**: Veo 2, Veo 3
- **PixVerse**: PixVerse v3
- **MiniMax Hailuo**: video-01

### Music Models
- **Suno**: Suno v4
- **Udio**: Udio v1.5
- **MusicGen / AudioCraft** (local)

### Audio Models
- **OpenAI Whisper**: STT
- **ElevenLabs**: TTS, voice cloning, speech-to-speech
- **AssemblyAI**: STT + LeMUR analysis

## Key Features

- **Multi-model conversations** - Switch providers mid-thread, compare responses
- **AI routing** - Auto-select best model per task type (coding, vision, reasoning)
- **Provider fallback** - Failover across providers on errors
- **Health monitoring** - Real-time provider availability tracking
- **Token & cost tracking** - Per-request, per-provider, per-day breakdown
- **Streaming** - SSE-based real-time token streaming
- **Encrypted storage** - AES-256-GCM via Android Keystore
- **Biometric lock** - Fingerprint/face authentication
- **Audit logs** - Track all API calls and access events
- **Glassmorphism UI** - Material 3 + premium animations (60fps)
- **Offline support** - Local Hive persistence for conversations
- **MCP marketplace** - Install tools for filesystem, browser, database, Git, etc.
- **Code IDE** - Multi-tab editor with diagnostics and AI assistance
- **Terminal** - Termux-style with bash/zsh/python/node support
- **Runtime** - Execute code in 15+ languages
- **Cloud sync** - Google Drive, Dropbox, GitHub, GitLab, OneDrive
- **Document AI** - PDF, Word, Excel, PPT, Markdown processing
- **Voice assistant** - Real-time STT + TTS + translation
- **Research mode** - Web search with citations and fact-checking

## Setup

### Prerequisites
- Flutter 3.22+ / Dart 3.4+
- Android SDK 34 (minSdk 23)
- Java 17
- Android Studio or VS Code

### Installation
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run --flavor production
```

### Configuration
1. Copy `.env.example` to `.env` (already provided)
2. Launch the app
3. Go to **Settings → API Keys**
4. Enter your provider API keys (encrypted at rest)

### Building a Release APK
```bash
flutter build apk --flavor production --release --split-per-abi
```

## Security

- API keys encrypted with **AES-256-GCM** using a master key stored in Android Keystore
- Optional **biometric lock** (fingerprint/face) on app launch
- **No telemetry** by default — Crashlytics + Sentry only enabled if user opts in
- Audit logs for all sensitive operations
- Network security config blocks cleartext traffic (except localhost for local LLMs)

## Testing

```bash
flutter test                              # Unit + widget tests
flutter test integration_test/            # Integration tests
flutter drive --target=test_driver/app.dart
```

## CI/CD Pipelines

This repository ships a complete GitHub Actions CI/CD system. Every workflow lives in `.github/workflows/` and runs immediately after pushing to GitHub — no additional setup required (beyond signing secrets for release builds).

### Workflow overview

| Workflow | Trigger | Purpose |
|---|---|---|
| `ci.yml` | Push to any branch + every PR | `dart analyze` + `flutter analyze` + `flutter test` + format check |
| `code-quality.yml` | Nightly + PRs to main/develop | Scans for TODO/FIXME/placeholder/UnimplementedError + hardcoded secrets + empty catch blocks |
| `build-apk.yml` | `workflow_dispatch` + called by release | Builds release APKs split per ABI (arm64-v8a, armeabi-v7a, x86_64) |
| `build-aab.yml` | `workflow_dispatch` + called by release | Builds release AAB for Play Store submission |
| `release.yml` | Push of git tag `v*.*.*` | Auto-creates GitHub Release with APK + AAB + changelog + checksums |

### Quickstart

```bash
# 1. Push to any branch → CI runs automatically
git push origin feature/my-feature

# 2. Open a PR → CI + Code Quality run on the PR
gh pr create --fill

# 3. Tag a release → APK + AAB + GitHub Release produced automatically
git tag v1.0.0
git push origin v1.0.0
# → https://github.com/<you>/omniforge_ai/releases/tag/v1.0.0
```

### Required GitHub Secrets (for signed release builds)

Configure these under **Settings → Secrets and variables → Actions → New repository secret**:

| Secret name | Purpose |
|---|---|
| `SIGNING_KEYSTORE_BASE64` | Base64-encoded `.keystore` file (`base64 -w0 release.keystore`) |
| `SIGNING_KEYSTORE_PASSWORD` | Keystore password |
| `SIGNING_KEY_PASSWORD` | Key password |
| `SIGNING_KEY_ALIAS` | Key alias (e.g. `omniforge`) |
| `SLACK_WEBHOOK_URL` | Optional — Slack webhook for build failure notifications |

Without these secrets, the build still succeeds but produces a **debug-signed** APK/AAB (sufficient for testing, not for Play Store).

### Generating a release keystore

```bash
keytool -genkeypair \
  -v \
  -keystore release.keystore \
  -alias omniforge \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -storepass <keystore-password> \
  -keypass <key-password>

# Encode for GitHub Secrets:
base64 -w0 release.keystore > release.keystore.base64
# Copy the contents of release.keystore.base64 into the
# SIGNING_KEYSTORE_BASE64 secret.
```

### Build caching strategy

Every workflow caches aggressively for fast rebuilds:

- **Gradle cache** keyed by `android/**/*.gradle*` + gradle-wrapper.properties
- **Pub cache** keyed by `pubspec.lock`
- **Flutter SDK cache** (built into `subosito/flutter-action@v2`)
- **Build artifacts** retained 30 days (APK) or 90 days (AAB + mapping.txt)

Typical rebuild time after cache warm-up: **~4 minutes** for CI, **~12 minutes** for APK, **~10 minutes** for AAB.

### Release notes generation

Releases are automatically annotated with:

1. **Commit-list changelog** — every commit since the previous tag, grouped by category
2. **Installation instructions** — APK architecture guide + Play Store AAB note
3. **Verification section** — SHA-256 checksums for all artifacts

To customize the changelog format, edit the `prepare-release` job in `.github/workflows/release.yml`.

### Branch protection recommendations

For the `main` branch, enable under **Settings → Branches → Branch protection rules**:

- ✅ Require pull request reviews before merging (minimum 1 reviewer)
- ✅ Require status checks to pass: `Analyze & Test`, `Forbidden Patterns Scan`
- ✅ Require branches to be up to date before merging
- ✅ Require conversation resolution before merging
- ✅ Require linear history (avoids merge commits)
- ✅ Require CODEOWNERS review for paths in `.github/CODEOWNERS`
- ✅ Do not allow bypassing the above settings

### Local CI reproduction

Run the same checks CI runs, locally:

```bash
# Analyze + format check + tests (matches ci.yml)
dart format --output=none --set-exit-if-changed lib/ test/
dart analyze --fatal-infos --fatal-warnings lib/ test/
flutter analyze --no-pub --current-package
dart run build_runner build --delete-conflicting-outputs
flutter test --coverage

# Build APK (matches build-apk.yml)
flutter build apk --release --flavor production --split-per-abi --no-tree-shake-icons

# Build AAB (matches build-aab.yml)
flutter build appbundle --release --flavor production --no-tree-shake-icons

# Forbidden patterns scan (matches code-quality.yml)
grep -rn "TODO\|FIXME\|XXX\|HACK\|UnimplementedError\|UnsupportedError" lib/ --include="*.dart"
grep -rni "real impl\|not yet implemented\|placeholder\|stub" lib/ --include="*.dart"
```

## Issue Templates + Pull Requests

- **Bug report**: `.github/ISSUE_TEMPLATE/bug_report.md`
- **Feature request**: `.github/ISSUE_TEMPLATE/feature_request.md`
- **Pull request template**: `.github/pull_request_template.md`
- **Code owners**: `.github/CODEOWNERS`
- **Dependabot config**: `.github/dependabot.yml` (weekly pub + GitHub Actions + monthly Gradle updates)

## License

Proprietary. All rights reserved.

## Built with

- Flutter 3.22+
- Dart 3.4+
- BLoC pattern (flutter_bloc + hydrated_bloc)
- GetIt for DI
- Dio for HTTP
- Hive for local persistence
- GoRouter for navigation
- Material 3 + custom glassmorphism design system
