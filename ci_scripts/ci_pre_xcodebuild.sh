#!/usr/bin/env bash
# ci_pre_xcodebuild.sh — Runs in Xcode Cloud before every build.
# Sets the build number from CI_BUILD_NUMBER and injects API key secrets.

set -euo pipefail

# ── Build number ────────────────────────────────────────────────────────────
# CI_BUILD_NUMBER is provided automatically by Xcode Cloud (1, 2, 3, …).
# We write it into Info.plist so App Store Connect sees a unique build number
# on every upload without any manual bumping.

if [ -n "${CI_BUILD_NUMBER:-}" ]; then
    INFO_PLIST="${CI_PRIMARY_REPOSITORY_PATH}/AAC/Info.plist"
    echo "📦 Setting CFBundleVersion to ${CI_BUILD_NUMBER}"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${CI_BUILD_NUMBER}" "$INFO_PLIST"
else
    echo "ℹ️  CI_BUILD_NUMBER not set — skipping build number update (local build)"
fi

# ── Secrets ─────────────────────────────────────────────────────────────────
# GROQ_API_KEY and OPENAI_API_KEY must be set as secret environment variables
# in the Xcode Cloud workflow (Xcode → Product → Xcode Cloud → Manage Workflows
# → Edit → Environment → Environment Variables, check "Secret").
#
# The existing generate_secrets.sh build phase reads these same env vars,
# so no additional work is needed here — just verify they're present.

echo "🔐 Checking secret environment variables..."

MISSING=0
if [ -z "${GROQ_API_KEY:-}" ]; then
    echo "   ⚠️  GROQ_API_KEY is not set — Groq TTS will be unavailable"
    MISSING=$((MISSING + 1))
else
    echo "   ✅ GROQ_API_KEY present"
fi

if [ -z "${OPENAI_API_KEY:-}" ]; then
    echo "   ⚠️  OPENAI_API_KEY is not set — OpenAI TTS will be unavailable"
    MISSING=$((MISSING + 1))
else
    echo "   ✅ OPENAI_API_KEY present"
fi

if [ "$MISSING" -gt 0 ]; then
    echo "   ℹ️  Add missing keys in: Xcode Cloud workflow → Environment → Environment Variables"
fi

echo "✅ ci_pre_xcodebuild.sh complete"
