#!/usr/bin/env bash
set -euo pipefail

# ─── Configuration ───────────────────────────────────────────────────
APP_NAME="kodi"
SCHEME="kodi"
PROJECT="kodi.xcodeproj"
BUNDLE_ID="nl.janyk.kodi"
ARCHIVE_PATH="build/${APP_NAME}.xcarchive"
EXPORT_PATH="build/export"
DMG_PATH="build/${APP_NAME}.dmg"

# ─── Team selection ──────────────────────────────────────────────────
select_team() {
    echo "Fetching available Developer ID teams..."
    echo ""

    # Extract Team ID + Name from "Developer ID Application: Name (TEAMID)" certs
    local raw_identities
    raw_identities=$(security find-identity -v -p codesigning 2>/dev/null \
        | grep "Developer ID Application" \
        | grep -oE '"Developer ID Application: [^"]+"' \
        | sed 's/"//g' \
        | sort -u || true)

    # Also grab regular Apple Development certs for dev builds
    local dev_identities
    dev_identities=$(security find-identity -v -p codesigning 2>/dev/null \
        | grep -E '"(Apple Development|Apple Distribution|3rd Party Mac Developer)' \
        | grep -oE '"[^"]+"' \
        | sed 's/"//g' \
        | sort -u || true)

    # Combine and deduplicate
    local all_identities
    all_identities=$(printf '%s\n%s' "$raw_identities" "$dev_identities" | grep -v '^$' | sort -u)

    if [[ -z "$all_identities" ]]; then
        echo "No signing identities found in keychain."
        echo ""
        echo "You can still proceed by entering your Team ID manually."
        echo "Find your Team ID at: https://developer.apple.com/account#MembershipDetailsCard"
        echo ""
        read -rp "Team ID: " TEAM_ID
        SIGNING_IDENTITY="Developer ID Application"
        return
    fi

    echo "Available signing identities:"
    echo ""
    local i=1
    local identities=()
    while IFS= read -r line; do
        # Extract team ID from parentheses
        local team_id
        team_id=$(echo "$line" | grep -oE '\([A-Z0-9]+\)$' | tr -d '()')
        echo "  ${i}) ${line}"
        identities+=("$line")
        ((i++))
    done <<< "$all_identities"

    echo ""
    read -rp "Select identity number [1]: " choice
    choice=${choice:-1}

    if (( choice < 1 || choice > ${#identities[@]} )); then
        echo "Invalid selection."
        exit 1
    fi

    SIGNING_IDENTITY="${identities[$((choice-1))]}"
    # Extract Team ID from the identity string
    TEAM_ID=$(echo "$SIGNING_IDENTITY" | grep -oE '\([A-Z0-9]+\)$' | tr -d '()')

    echo ""
    echo "Using identity: ${SIGNING_IDENTITY}"
    echo "Team ID: ${TEAM_ID}"
}

# ─── Apple ID for notarization ───────────────────────────────────────
get_notarization_credentials() {
    if [[ -n "${KEYCHAIN_PROFILE:-}" ]]; then
        echo "Using keychain profile from environment: ${KEYCHAIN_PROFILE}"
        return
    fi

    echo ""
    echo "Notarization requires a stored keychain profile."
    echo "If you haven't set one up yet, run:"
    echo "  xcrun notarytool store-credentials \"notarytool-profile\" \\"
    echo "    --apple-id \"your@email.com\" --team-id \"${TEAM_ID}\" --password \"app-specific-password\""
    echo ""
    read -rp "Keychain profile name [notarytool-profile]: " KEYCHAIN_PROFILE
    KEYCHAIN_PROFILE=${KEYCHAIN_PROFILE:-notarytool-profile}
}

# ─── Build ───────────────────────────────────────────────────────────
build() {
    echo "==> Archiving ${APP_NAME}..."
    xcodebuild archive \
        -project "${PROJECT}" \
        -scheme "${SCHEME}" \
        -configuration Release \
        -archivePath "${ARCHIVE_PATH}" \
        DEVELOPMENT_TEAM="${TEAM_ID}" \
        CODE_SIGN_IDENTITY="${SIGNING_IDENTITY}" \
        CODE_SIGN_STYLE=Manual \
        -quiet

    echo "==> Archive created at ${ARCHIVE_PATH}"
}

# ─── Export ──────────────────────────────────────────────────────────
export_app() {
    local export_plist="build/ExportOptions.plist"

    cat > "${export_plist}" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>${TEAM_ID}</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>${SIGNING_IDENTITY}</string>
</dict>
</plist>
PLIST

    echo "==> Exporting app..."
    xcodebuild -exportArchive \
        -archivePath "${ARCHIVE_PATH}" \
        -exportOptionsPlist "${export_plist}" \
        -exportPath "${EXPORT_PATH}" \
        -quiet

    echo "==> Exported to ${EXPORT_PATH}/${APP_NAME}.app"
}

# ─── Create DMG ──────────────────────────────────────────────────────
create_dmg() {
    echo "==> Creating DMG..."
    rm -f "${DMG_PATH}"
    hdiutil create \
        -volname "${APP_NAME}" \
        -srcfolder "${EXPORT_PATH}/${APP_NAME}.app" \
        -ov \
        -format UDZO \
        "${DMG_PATH}" \
        -quiet

    # Sign the DMG
    codesign --sign "${SIGNING_IDENTITY}" "${DMG_PATH}"
    echo "==> DMG created at ${DMG_PATH}"
}

# ─── Notarize ────────────────────────────────────────────────────────
notarize() {
    echo "==> Submitting for notarization..."
    xcrun notarytool submit "${DMG_PATH}" \
        --keychain-profile "${KEYCHAIN_PROFILE}" \
        --wait

    echo "==> Stapling notarization ticket..."
    xcrun stapler staple "${DMG_PATH}"

    echo ""
    echo "==> Done! Notarized DMG: ${DMG_PATH}"
}

# ─── Main ────────────────────────────────────────────────────────────
main() {
    cd "$(dirname "$0")/.."
    mkdir -p build

    select_team
    get_notarization_credentials
    build
    export_app
    create_dmg
    notarize
}

main "$@"
