#!/usr/bin/env bash
# generate_secrets.sh — Generates GeneratedSecrets.swift from env vars or Secrets.plist
# Used as an Xcode build phase and by Xcode Cloud CI.

set -euo pipefail

echo "🔐 Generating secrets..."

OUTPUT_FILE="${SRCROOT}/AAC/Services/GeneratedSecrets.swift"

GROQ_KEY="${GROQ_API_KEY:-}"
OPENAI_KEY="${OPENAI_API_KEY:-}"

# Try environment variables first (Xcode Cloud), then Secrets.plist
if [ -z "$GROQ_KEY" ] && [ -f "${SRCROOT}/Secrets.plist" ]; then
    GROQ_KEY=$(/usr/libexec/PlistBuddy -c "Print :GROQ_API_KEY" "${SRCROOT}/Secrets.plist" 2>/dev/null || echo "")
    echo "   ✅ GROQ_API_KEY loaded from Secrets.plist"
elif [ -n "$GROQ_KEY" ]; then
    echo "   ✅ GROQ_API_KEY loaded from environment"
else
    echo "   ⚠️  GROQ_API_KEY not found — using placeholder"
    GROQ_KEY="YOUR_GROQ_API_KEY_HERE"
fi

if [ -z "$OPENAI_KEY" ] && [ -f "${SRCROOT}/Secrets.plist" ]; then
    OPENAI_KEY=$(/usr/libexec/PlistBuddy -c "Print :OPENAI_API_KEY" "${SRCROOT}/Secrets.plist" 2>/dev/null || echo "")
    echo "   ✅ OPENAI_API_KEY loaded from Secrets.plist"
elif [ -n "$OPENAI_KEY" ]; then
    echo "   ✅ OPENAI_API_KEY loaded from environment"
else
    echo "   ⚠️  OPENAI_API_KEY not found — using placeholder"
    OPENAI_KEY="YOUR_OPENAI_API_KEY_HERE"
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
}
EOF

echo "   ✅ Generated: $OUTPUT_FILE"
