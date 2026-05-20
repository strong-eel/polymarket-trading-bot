# Bullpen Copy Trading Bot

A fully automated Polymarket copy-trading setup powered by the [Bullpen CLI](https://cli.bullpen.fi). Copy the trades of top Polymarket traders in real time, monitor your positions through a live web dashboard, and automatically redeem wins and wrap USDC back to pUSD for trading.

## What This Does

- **Copy-trades** selected Polymarket traders automatically
- **Live dashboard** showing your positions, pending trades, subscriptions, and execution history
- **Auto-redeems** winning positions and wraps USDC.e back to pUSD so your balance stays ready to trade
- Anyone can clone this repo, follow the setup, and be trading within minutes

## Dashboard Preview

The dashboard runs locally at `http://localhost:8765` and shows:
- pUSD balance and open positions with live P&L
- Pending copy trades waiting for confirmation (with countdown timer)
- All active copy-trade subscriptions and their configs
- Full execution history with status (Executed / Skipped / Rejected / Pending)

## Prerequisites

- macOS or Linux
- [Homebrew](https://brew.sh) (macOS)
- Python 3 (pre-installed on macOS)
- A [Polymarket](https://polymarket.com) account

## Setup

### 1. Install Bullpen CLI

```bash
brew install bullpenfi/tap/bullpen
```

### 2. Log in to Bullpen

```bash
bullpen login
```

### 3. Fund your Polymarket wallet

```bash
bullpen deposit
```

This opens the Bullpen web app. Deposit USDC — then wrap it to pUSD (the collateral used for trading):

```bash
bullpen polymarket wrap <amount> --yes
```

### 4. Find traders to copy

Browse the leaderboard to find top traders:

```bash
bullpen polymarket data leaderboard --time-period 7d --sort copyability --hide-farmers --limit 10
```

### 5. Start copy-trading

```bash
bullpen tracker copy start <TRADER_ADDRESS> --preset recommended
```

Recommended settings used in this setup:
- Sizing mode: `fixed` — $2 per trade (safe floor above Polymarket's $1 minimum)
- Min source trade size: $1 (catches even small probe trades)
- Exit behavior: `mirror_sells` (auto-exits when the trader exits)
- Execution mode: `auto` (no confirmation needed)

To apply these manually:

```bash
bullpen tracker copy start <ADDRESS> \
  --sizing-mode fixed \
  --fixed-amount 2 \
  --min-trade-size 1 \
  --exit-behavior mirror_sells \
  --execution-mode auto \
  --yes
```

### 6. Start the dashboard

```bash
cd bullpen-dashboard
./start.sh
```

Open `http://localhost:8765` in your browser.

## Automating Redeems and Wraps

`redeem-and-wrap.sh` checks for redeemable winning positions and any unwrapped USDC.e, and handles both automatically. Run it on a schedule via cron:

```bash
crontab -e
```

Add (runs every 30 minutes):

```
*/30 * * * * /path/to/bullpen-dashboard/redeem-and-wrap.sh
```

Or run manually anytime:

```bash
./bullpen-dashboard/redeem-and-wrap.sh
```

Logs are written to `~/Documents/bullpen-dashboard/redeem-wrap.log`.

## File Structure

```
bullpen-dashboard/
├── index.html          # Dashboard UI (single-page app)
├── server.py           # Local API server wrapping Bullpen CLI (port 8765)
├── start.sh            # Starts the dashboard server
└── redeem-and-wrap.sh  # Auto-redeems wins and wraps USDC.e → pUSD
```

## Key Bullpen Commands

| Task | Command |
|---|---|
| Check positions | `bullpen polymarket positions` |
| Check balance | `bullpen portfolio balances` |
| Redeem wins | `bullpen polymarket redeem --yes` |
| Wrap USDC → pUSD | `bullpen polymarket wrap <amount> --yes` |
| List copy subscriptions | `bullpen tracker copy list` |
| View execution history | `bullpen tracker copy executions` |
| Upgrade CLI | `bullpen upgrade` |

## Tips

- **Sizing:** Keep copy amounts at `$2` fixed when your balance is under ~$100. Scale up as your balance grows.
- **Min trade size:** Set to `$1` to copy even small probe trades from followed traders.
- **Rejected trades:** If trades show as "Rejected", it usually means the copy amount fell below Polymarket's $1 minimum — switch to fixed sizing.
- **Skipped trades:** If trades are "Skipped", the source trader's trade was below your `min_trade_size` threshold — lower it.
- **RPC errors on redeem:** If redeeming fails with an RPC error, file a support ticket at [bullpen-help.freshdesk.com](https://bullpen-help.freshdesk.com/support/tickets/new) — this is a Bullpen infrastructure issue, not on your end.

## Resources

- [Bullpen CLI Docs](https://cli.bullpen.fi)
- [Bullpen Discord](https://discord.com/invite/bullpen)
- [Bullpen Support](https://bullpen-help.freshdesk.com/support/tickets/new)
- [Polymarket](https://polymarket.com)
