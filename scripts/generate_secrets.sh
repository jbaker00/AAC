#!/usr/bin/env bash
# generate_secrets.sh — Generates GeneratedSecrets.swift from env vars or Secrets.plist
# Used as an Xcode build phase and by Xcode Cloud CI.

set -euo pipefail

echo "🔐 Generating secrets..."

OUTPUT_FILE="${SRCROOT}/My Words/Services/GeneratedSecrets.swift"
INFO_PLIST="${SRCROOT}/My Words/Info.plist"
SECRETS_PLIST="${SRCROOT}/Secrets.plist"

GROQ_KEY="${GROQ_API_KEY:-}"
OPENAI_KEY="${OPENAI_API_KEY:-}"
ADMOB_APP="${ADMOB_APP_ID:-}"
ADMOB_BANNER="${ADMOB_BANNER_AD_UNIT_ID:-}"

# Try environment variables first (Xcode Cloud), then Secrets.plist
if [ -z "$GROQ_KEY" ] && [ -f "$SECRETS_PLIST" ]; then
    GROQ_KEY=$(/usr/libexec/PlistBuddy -c "Print :GROQ_API_KEY" "$SECRETS_PLIST" 2>/dev/null || echo "")
    echo "   ✅ GROQ_API_KEY loaded from Secrets.plist"
elif [ -n "$GROQ_KEY" ]; then
    echo "   ✅ GROQ_API_KEY loaded from environment"
else
    echo "   ⚠️  GROQ_API_KEY not found — using placeholder"
    GROQ_KEY="YOUR_GROQ_API_KEY_HERE"
fi

if [ -z "$OPENAI_KEY" ] && [ -f "$SECRETS_PLIST" ]; then
    OPENAI_KEY=$(/usr/libexec/PlistBuddy -c "Print :OPENAI_API_KEY" "$SECRETS_PLIST" 2>/dev/null || echo "")
    echo "   ✅ OPENAI_API_KEY loaded from Secrets.plist"
elif [ -n "$OPENAI_KEY" ]; then
    echo "   ✅ OPENAI_API_KEY loaded from environment"
else
    echo "   ⚠️  OPENAI_API_KEY not found — using placeholder"
    OPENAI_KEY="YOUR_OPENAI_API_KEY_HERE"
fi

if [ -z "$ADMOB_APP" ] && [ -f "$SECRETS_PLIST" ]; then
    ADMOB_APP=$(/usr/libexec/PlistBuddy -c "Print :ADMOB_APP_ID" "$SECRETS_PLIST" 2>/dev/null || echo "")
    echo "   ✅ ADMOB_APP_ID loaded from Secrets.plist"
elif [ -n "$ADMOB_APP" ]; then
    echo "   ✅ ADMOB_APP_ID loaded from environment"
else
    echo "   ⚠️  ADMOB_APP_ID not found — using placeholder"
    ADMOB_APP="ca-app-pub-PLACEHOLDER~0000000000"
fi

if [ -z "$ADMOB_BANNER" ] && [ -f "$SECRETS_PLIST" ]; then
    ADMOB_BANNER=$(/usr/libexec/PlistBuddy -c "Print :ADMOB_BANNER_AD_UNIT_ID" "$SECRETS_PLIST" 2>/dev/null || echo "")
    echo "   ✅ ADMOB_BANNER_AD_UNIT_ID loaded from Secrets.plist"
elif [ -n "$ADMOB_BANNER" ]; then
    echo "   ✅ ADMOB_BANNER_AD_UNIT_ID loaded from environment"
else
    echo "   ⚠️  ADMOB_BANNER_AD_UNIT_ID not found — using test ad unit"
    ADMOB_BANNER="ca-app-pub-3940256099942544/2934735716"
fi


cat > "$OUTPUT_FILE" << EOF
import Foundation

/// Auto-generated — DO NOT EDIT
/// Generated at build time from environment variables or Secrets.plist
enum Secrets {
    static var groqApiKey: String? {
        // 1) Environment variable (runtime override)
        if let env = ProcessInfo.processInfo.environment["GROQ_API_KEY"], !env.isEmpty {
            return env
        }
        // 2) Build-time injected key
        let key = "${GROQ_KEY}"
        return key.hasPrefix("YOUR_") ? nil : key
    }

    static var openAIApiKey: String? {
        if let env = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !env.isEmpty {
            return env
        }
        let key = "${OPENAI_KEY}"
        return key.hasPrefix("YOUR_") ? nil : key
    }

    static var admobBannerAdUnitId: String? {
        if let env = ProcessInfo.processInfo.environment["ADMOB_BANNER_AD_UNIT_ID"], !env.isEmpty {
            return env
        }
        let key = "${ADMOB_BANNER}"
        return key.hasPrefix("ca-app-pub-3940256099942544") ? nil : key
    }
}
EOF

echo "   ✅ Generated: $OUTPUT_FILE"
