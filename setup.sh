#!/bin/bash
set -e

echo ""
echo "======================================"
echo "  Bullpen Polymarket Bot - Setup"
echo "======================================"
echo ""

# 1. Check for Homebrew (macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
  if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    echo "✓ Homebrew already installed"
  fi
fi

# 2. Install Bullpen CLI
if ! command -v bullpen &>/dev/null; then
  echo "Installing Bullpen CLI..."
  brew install bullpenfi/tap/bullpen
else
  echo "✓ Bullpen CLI already installed ($(bullpen --version 2>/dev/null || echo 'unknown version'))"
  echo "  Checking for updates..."
  bullpen upgrade 2>/dev/null || true
fi

# 3. Check for jq (needed for the session-start hook)
if ! command -v jq &>/dev/null; then
  echo "Installing jq..."
  brew install jq
else
  echo "✓ jq already installed"
fi

# 4. Install Claude Code session-start hook (auto-wrap USDC on session start)
SETTINGS="$HOME/.claude/settings.json"
mkdir -p "$HOME/.claude"

HOOK_COMMAND='PREFLIGHT=$(bullpen polymarket preflight --output json 2>/dev/null); USDC=$(echo "$PREFLIGHT" | jq -r '"'"'(.usdc_e_balance // "0" | tonumber) > 0'"'"'); if [ "$USDC" = "true" ]; then AMOUNT=$(echo "$PREFLIGHT" | jq -r '"'"'.usdc_e_balance_usd | ltrimstr("$")'"'"'); bullpen polymarket wrap "$AMOUNT" --yes 2>/dev/null; fi'

if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
fi

# Check if hook already exists
if jq -e '.hooks.SessionStart' "$SETTINGS" &>/dev/null; then
  echo "✓ Claude Code session-start hook already configured"
else
  echo "Configuring Claude Code session-start hook (auto-wrap USDC)..."
  TEMP=$(mktemp)
  jq --arg cmd "$HOOK_COMMAND" '
    .hooks.SessionStart = [
      {
        "hooks": [
          {
            "type": "command",
            "command": $cmd,
            "statusMessage": "Checking for unwrapped USDC...",
            "timeout": 30
          }
        ]
      }
    ]
  ' "$SETTINGS" > "$TEMP" && mv "$TEMP" "$SETTINGS"
  echo "✓ Session-start hook installed"
fi

# 5. Make scripts executable
chmod +x bullpen-dashboard/start.sh bullpen-dashboard/redeem-and-wrap.sh
echo "✓ Scripts made executable"

echo ""
echo "======================================"
echo "  Setup complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo ""
echo "  1. Log in to Bullpen:"
echo "     bullpen login"
echo ""
echo "  2. Deposit USDC and wrap to pUSD:"
echo "     bullpen deposit"
echo "     bullpen polymarket wrap <amount> --yes"
echo ""
echo "  3. Find traders to copy:"
echo "     bullpen polymarket data leaderboard --time-period 7d --sort copyability --hide-farmers --limit 10"
echo ""
echo "  4. Start copying a trader:"
echo "     bullpen tracker copy start <TRADER_ADDRESS> --sizing-mode fixed --fixed-amount 2 --min-trade-size 1 --exit-behavior mirror_sells --execution-mode auto --yes"
echo ""
echo "  5. Start the dashboard:"
echo "     cd bullpen-dashboard && ./start.sh"
echo "     Open http://localhost:8765"
echo ""
echo "  Tip: Open this project in Claude Code for guided help with any step."
echo ""
