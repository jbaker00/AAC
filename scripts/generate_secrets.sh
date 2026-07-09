#!/usr/bin/env bash
# generate_secrets.sh — Generates GeneratedSecrets.swift from env vars or Secrets.plist
# Used as an Xcode build phase and by Xcode Cloud CI.
# API keys no longer ship in the app — Groq/OpenAI calls go through the api-proxy
# Cloud Function. Only AdMob IDs (public identifiers) are generated here.

set -euo pipefail

echo "🔐 Generating secrets..."

OUTPUT_FILE="${SRCROOT}/My Words/Services/GeneratedSecrets.swift"
SECRETS_PLIST="${SRCROOT}/Secrets.plist"

ADMOB_BANNER="${ADMOB_BANNER_AD_UNIT_ID:-}"

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
/// Generated at build time from environment variables or Secrets.plist.
/// All API calls go through the api-proxy Cloud Function — no keys ship in the app.
enum Secrets {
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
