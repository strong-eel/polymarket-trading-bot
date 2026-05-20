# Bullpen Polymarket Copy-Trading Bot

This project lets you automatically copy-trade top Polymarket traders using the Bullpen CLI, with a live web dashboard to monitor positions, pending trades, and execution history.

## Project Structure

- `bullpen-dashboard/index.html` — Single-page dashboard UI (auto-refreshes every 30s)
- `bullpen-dashboard/server.py` — Local API server (port 8765) that wraps Bullpen CLI commands
- `bullpen-dashboard/start.sh` — Starts the dashboard server
- `bullpen-dashboard/redeem-and-wrap.sh` — Auto-redeems winning positions and wraps USDC.e → pUSD
- `setup.sh` — One-shot setup script (installs deps, configures hooks, walks through onboarding)

## If a User Asks to Set Up This Bot

Run `setup.sh` first, then walk them through these steps in order:

1. **Install Bullpen CLI**: `brew install bullpenfi/tap/bullpen`
2. **Log in**: `bullpen login`
3. **Check status**: `bullpen status`
4. **Deposit funds**: `bullpen deposit` (opens web app — deposit USDC)
5. **Wrap USDC to pUSD**: `bullpen polymarket wrap <amount> --yes`
6. **Find traders to copy**: `bullpen polymarket data leaderboard --time-period 7d --sort copyability --hide-farmers --limit 10`
7. **Start copying a trader**: `bullpen tracker copy start <ADDRESS> --sizing-mode fixed --fixed-amount 2 --min-trade-size 1 --exit-behavior mirror_sells --execution-mode auto --yes`
8. **Start dashboard**: `cd bullpen-dashboard && ./start.sh` then open http://localhost:8765

## Automated Tasks

### Session-Start Hook (auto-wrap USDC)
The `setup.sh` script installs a Claude Code session-start hook in `~/.claude/settings.json` that automatically wraps any USDC.e to pUSD every time a Claude Code session starts. If the user hasn't run setup.sh, install it by adding this to their `~/.claude/settings.json` under `hooks.SessionStart`:

```json
{
  "type": "command",
  "command": "PREFLIGHT=$(bullpen polymarket preflight --output json 2>/dev/null); USDC=$(echo \"$PREFLIGHT\" | jq -r '(.usdc_e_balance // \"0\" | tonumber) > 0'); if [ \"$USDC\" = \"true\" ]; then AMOUNT=$(echo \"$PREFLIGHT\" | jq -r '.usdc_e_balance_usd | ltrimstr(\"$\")'); bullpen polymarket wrap \"$AMOUNT\" --yes 2>/dev/null; fi",
  "statusMessage": "Checking for unwrapped USDC...",
  "timeout": 30
}
```

### Redeem and Wrap Script
Run manually or via cron to redeem wins and wrap USDC:
```bash
./bullpen-dashboard/redeem-and-wrap.sh
```

## Common Tasks (run these when asked)

- **Check positions**: `bullpen polymarket positions`
- **Check balance**: `bullpen portfolio balances`
- **Redeem wins**: `bullpen polymarket redeem --yes`
- **Wrap USDC**: `bullpen polymarket wrap <amount> --yes`
- **View copy trades**: `bullpen tracker copy list`
- **View execution history**: `bullpen tracker copy executions`
- **View pending trades**: `bullpen tracker copy pending`
- **Upgrade CLI**: `bullpen upgrade`

## Copy-Trade Sizing Rules

All subscriptions should use fixed $2 sizing with $1 min trade size to avoid Polymarket's $1 minimum order rejection. If trades show as "Rejected" with a sub-$1 amount error, fix with:
```bash
bullpen tracker copy edit <TRADER_ADDRESS> --amount 2 --min-trade-size 1 --yes
```

## Known Issues

- **RPC errors on redeem**: Bullpen's Polygon RPC occasionally goes down. File a ticket at https://bullpen-help.freshdesk.com if redeem fails with "tenant disabled" errors. Positions are safe — retry later.
