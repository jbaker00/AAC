# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

"My Words - AAC Communication" is an iOS native app (Swift/SwiftUI) for Augmentative and Alternative Communication — helping users communicate via picture-based buttons with AI-powered text-to-speech. Targets iOS 16.0+, supports iPhone and iPad.

## Build & Development

**Generate Xcode project (required after changing `project.yml`):**
```bash
xcodegen generate
```

Then open `AAC.xcodeproj` in Xcode, select the "AAC" target, and run on a simulator or device.

**Secrets setup:** API keys live in `Secrets.plist` (not committed). The build pre-action runs `scripts/generate_secrets.sh` which reads from `Secrets.plist` or environment variables and generates `AAC/Services/GeneratedSecrets.swift` at build time.

There are no automated tests in this project.

## Architecture

**MVVM with SwiftUI.** State flows via `@StateObject` and `@Published`.

- **`Models/AACItem.swift`** — Core data model for a communication button (label, emoji, image path, custom phrase).
- **`Models/ItemStore.swift`** — Persistence layer; reads/writes `AACItem` arrays as JSON to the app's Documents directory. Also manages photo file storage.
- **`Services/TextToSpeechManager.swift`** — Central TTS orchestrator. Selects between three providers based on user settings: Groq Orpheus (cloud), OpenAI TTS (cloud), or iOS system AVSpeechSynthesizer. Manages AVAudioSession and playback state.
- **`Services/GroqTTSService.swift`** / **`Services/OpenAITTSService.swift`** — Thin API wrappers for cloud TTS providers. API keys come from `GeneratedSecrets.swift`.
- **`Views/ContentView.swift`** — Main grid of AAC buttons; handles tap-to-speak and long-press-to-edit interactions.
- **`Views/ItemImages/`** — Custom SwiftUI vector illustrations for the 4 default built-in buttons (Milk, Potty, Toothbrush, Stroller).

## Xcode Cloud CI

**Build number** is set automatically from `CI_BUILD_NUMBER` (Xcode Cloud's auto-incrementing value) by `ci_scripts/ci_pre_xcodebuild.sh`. Never manually bump `CFBundleVersion` — it will be overwritten on CI.

**Secrets** (`GROQ_API_KEY`, `OPENAI_API_KEY`) must be added as **secret** environment variables in the Xcode Cloud workflow:
> Xcode → Product → Xcode Cloud → Manage Workflows → Edit → Environment → Environment Variables (check "Secret")

The existing `generate_secrets.sh` build phase already reads these env vars, so no other changes are needed.

## Key Configuration

- **`project.yml`** — XcodeGen config; defines the iOS target, deployment target, build scripts, and entitlements. Edit this (not the `.xcodeproj` directly) when changing project settings.
- **`Secrets.plist`** — Contains `GroqAPIKey` and `OpenAIAPIKey`. Never commit this file (already in `.gitignore`).
- **Bundle ID:** `com.jbaker.AAC` | **Team ID:** `G3P9A8Z2NP`
