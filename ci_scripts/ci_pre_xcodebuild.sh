#!/usr/bin/env bash
# ci_pre_xcodebuild.sh — Runs in Xcode Cloud before every build.
# Sets the build number from CI_BUILD_NUMBER and injects API key secrets.

set -euo pipefail

# ── Build number ────────────────────────────────────────────────────────────
# CI_BUILD_NUMBER is provided automatically by Xcode Cloud (1, 2, 3, …).
# We write it into Info.plist so App Store Connect sees a unique build number
# on every upload without any manual bumping.

if [ -n "${CI_BUILD_NUMBER:-}" ]; then
    INFO_PLIST="${CI_PRIMARY_REPOSITORY_PATH}/My Words/Info.plist"
    echo "📦 Setting CFBundleVersion to ${CI_BUILD_NUMBER}"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${CI_BUILD_NUMBER}" "$INFO_PLIST"
else
    echo "ℹ️  CI_BUILD_NUMBER not set — skipping build number update (local build)"
fi

# ── Secrets ─────────────────────────────────────────────────────────────────
# Groq/OpenAI TTS go through the api-proxy Cloud Function — no API keys needed.
# Only AdMob IDs (public identifiers) must be set in the Xcode Cloud workflow
# (Xcode → Product → Xcode Cloud → Manage Workflows → Edit → Environment):
#   ADMOB_APP_ID, ADMOB_BANNER_AD_UNIT_ID
#
# The generate_secrets.sh build phase reads these same env vars at compile time.

echo "🔐 Checking environment variables..."

MISSING=0

# ── AdMob — inject App ID into Info.plist before the build reads it ──────────
INFO_PLIST="${CI_PRIMARY_REPOSITORY_PATH}/My Words/Info.plist"

if [ -n "${ADMOB_APP_ID:-}" ]; then
    echo "   ✅ ADMOB_APP_ID present"
    if [ -f "$INFO_PLIST" ]; then
        /usr/libexec/PlistBuddy -c "Set :GADApplicationIdentifier ${ADMOB_APP_ID}" "$INFO_PLIST" 2>/dev/null || \
        /usr/libexec/PlistBuddy -c "Add :GADApplicationIdentifier string ${ADMOB_APP_ID}" "$INFO_PLIST"
        echo "   ✅ GADApplicationIdentifier written to Info.plist"
    fi
else
    echo "   ⚠️  ADMOB_APP_ID is not set — ads will not load"
    MISSING=$((MISSING + 1))
fi

if [ -z "${ADMOB_BANNER_AD_UNIT_ID:-}" ]; then
    echo "   ⚠️  ADMOB_BANNER_AD_UNIT_ID is not set — banner ads will not load"
    MISSING=$((MISSING + 1))
else
    echo "   ✅ ADMOB_BANNER_AD_UNIT_ID present"
fi

if [ "$MISSING" -gt 0 ]; then
    echo "   ℹ️  Add missing keys in: Xcode Cloud workflow → Environment → Environment Variables"
fi

echo "✅ ci_pre_xcodebuild.sh complete"
