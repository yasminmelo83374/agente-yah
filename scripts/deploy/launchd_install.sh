#!/usr/bin/env bash
set -euo pipefail

PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_NAME="com.agentplatform.sync.plist"
PLIST_PATH="$PLIST_DIR/$PLIST_NAME"
PROJECT_DIR="/Users/yasminmelo/Documents/New project"

mkdir -p "$PLIST_DIR"

cat > "$PLIST_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.agentplatform.sync</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>${PROJECT_DIR}/scripts/deploy/rsync_to_vps.sh</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>VPS_HOST</key>
    <string>129.121.34.228</string>
    <key>VPS_PORT</key>
    <string>22022</string>
    <key>VPS_USER</key>
    <string>root</string>
    <key>VPS_PATH</key>
    <string>/opt/agent-platform</string>
  </dict>
  <key>StartInterval</key>
  <integer>600</integer>
  <key>RunAtLoad</key>
  <true/>
  <key>StandardOutPath</key>
  <string>${PROJECT_DIR}/artifacts/launchd-sync.log</string>
  <key>StandardErrorPath</key>
  <string>${PROJECT_DIR}/artifacts/launchd-sync.err</string>
</dict>
</plist>
PLIST

mkdir -p "${PROJECT_DIR}/artifacts"

launchctl unload "$PLIST_PATH" >/dev/null 2>&1 || true
launchctl load "$PLIST_PATH"

cat <<MSG
Launchd instalado e carregado.
Para desativar: launchctl unload $PLIST_PATH
MSG
