#!/bin/bash
set -e

LABEL="com.marketwatch"
PLIST_PATH="$HOME/Library/LaunchAgents/${LABEL}.plist"
BINARY_PATH="/Users/vikasbhatia/code/marketwatch/MarketWatch"
LOG_PATH="/Users/vikasbhatia/code/marketwatch/marketwatch.log"

echo "=== Setting up MarketWatch macOS Auto-Start (Launch Agent) ==="

# 1. Stop any currently active launch agent instance
if launchctl list | grep -q "$LABEL"; then
    echo "Stopping existing launch agent..."
    launchctl unload "$PLIST_PATH" || true
fi

# 2. Write the plist file dynamically with correct absolute paths
echo "Generating Plist Agent at: $PLIST_PATH"
cat <<EOF > "$PLIST_PATH"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${LABEL}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${BINARY_PATH}</string>
        <string>-i</string>
        <string>120</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${LOG_PATH}</string>
    <key>StandardErrorPath</key>
    <string>${LOG_PATH}</string>
</dict>
</plist>
EOF

# 3. Secure file permissions (required by macOS Launch Services)
chmod 644 "$PLIST_PATH"

# 4. Load the launch agent instantly
echo "Loading Launch Agent into macOS session..."
launchctl load "$PLIST_PATH"

echo "=== Setup Complete! ==="
echo "MarketWatch is now registered. It will start automatically whenever your Mac boots/logs in."
echo "Active Logs are available at: tail -f $LOG_PATH"
